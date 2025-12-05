# =============================================================================
# ELK Stack Module for Jobzy Platform
# =============================================================================
# Deploys logging infrastructure using Helm:
# - Elasticsearch (log storage & search)
# - Logstash (log processing - optional)
# - Kibana (visualization)
# - Filebeat (log collection from pods)
# - Jaeger (distributed tracing)
# =============================================================================

# -----------------------------------------------------------------------------
# Namespace
# -----------------------------------------------------------------------------
resource "kubernetes_namespace" "logging" {
  metadata {
    name = var.namespace
    labels = merge(
      var.labels,
      {
        "name" = var.namespace
      }
    )
  }
}

# -----------------------------------------------------------------------------
# Elasticsearch
# -----------------------------------------------------------------------------
resource "helm_release" "elasticsearch" {
  name       = "elasticsearch"
  repository = "https://helm.elastic.co"
  chart      = "elasticsearch"
  version    = var.elasticsearch_version
  namespace  = kubernetes_namespace.logging.metadata[0].name

  values = [
    yamlencode({
      replicas = var.elasticsearch_replicas

      # Resource configuration
      resources = {
        requests = {
          cpu    = var.elasticsearch_cpu_request
          memory = var.elasticsearch_memory_request
        }
        limits = {
          cpu    = var.elasticsearch_cpu_limit
          memory = var.elasticsearch_memory_limit
        }
      }

      # JVM heap size (50% of memory limit)
      esJavaOpts = "-Xmx${var.elasticsearch_heap_size} -Xms${var.elasticsearch_heap_size}"

      # Persistence
      volumeClaimTemplate = {
        accessModes = ["ReadWriteOnce"]
        storageClassName = var.storage_class
        resources = {
          requests = {
            storage = var.elasticsearch_storage_size
          }
        }
      }

      # Cluster configuration
      clusterName = "jobzy-logs"
      nodeGroup   = "master"

      # Security (basic)
      protocol = "http"

      # Pod disruption budget
      maxUnavailable = 1

      # Anti-affinity for HA
      antiAffinity = var.elasticsearch_replicas > 1 ? "soft" : ""

      # Index lifecycle management
      esConfig = {
        "elasticsearch.yml" = <<-EOT
          cluster.name: jobzy-logs
          network.host: 0.0.0.0

          # ILM settings
          xpack.ilm.enabled: true

          # Disable security for internal use (enable for production)
          xpack.security.enabled: false

          # Disk watermarks
          cluster.routing.allocation.disk.watermark.low: 85%
          cluster.routing.allocation.disk.watermark.high: 90%
          cluster.routing.allocation.disk.watermark.flood_stage: 95%
        EOT
      }
    })
  ]

  depends_on = [kubernetes_namespace.logging]
}

# -----------------------------------------------------------------------------
# Kibana
# -----------------------------------------------------------------------------
resource "helm_release" "kibana" {
  name       = "kibana"
  repository = "https://helm.elastic.co"
  chart      = "kibana"
  version    = var.kibana_version
  namespace  = kubernetes_namespace.logging.metadata[0].name

  values = [
    yamlencode({
      # Elasticsearch connection
      elasticsearchHosts = "http://elasticsearch-master:9200"

      # Resources
      resources = {
        requests = {
          cpu    = "200m"
          memory = "512Mi"
        }
        limits = {
          cpu    = "1000m"
          memory = "1Gi"
        }
      }

      # Service configuration
      service = {
        type = var.kibana_service_type
        port = 5601
      }

      # Health checks
      healthCheckPath = "/app/kibana"

      # Kibana configuration
      kibanaConfig = {
        "kibana.yml" = <<-EOT
          server.name: kibana
          server.host: "0.0.0.0"
          elasticsearch.hosts: ["http://elasticsearch-master:9200"]

          # Logging
          logging.dest: stdout
          logging.verbose: false

          # Saved objects
          savedObjects.maxImportPayloadBytes: 26214400

          # Disable telemetry
          telemetry.enabled: false
        EOT
      }

      # Ingress
      ingress = {
        enabled = var.enable_ingress
        annotations = {
          "kubernetes.io/ingress.class" = "nginx"
        }
        hosts = [
          {
            host = var.kibana_host
            paths = [
              {
                path = "/"
              }
            ]
          }
        ]
        tls = var.enable_tls ? [
          {
            secretName = "kibana-tls"
            hosts      = [var.kibana_host]
          }
        ] : []
      }
    })
  ]

  depends_on = [helm_release.elasticsearch]
}

# -----------------------------------------------------------------------------
# Filebeat (Log Collection)
# -----------------------------------------------------------------------------
resource "helm_release" "filebeat" {
  name       = "filebeat"
  repository = "https://helm.elastic.co"
  chart      = "filebeat"
  version    = var.filebeat_version
  namespace  = kubernetes_namespace.logging.metadata[0].name

  values = [
    yamlencode({
      # Elasticsearch output
      filebeatConfig = {
        "filebeat.yml" = <<-EOT
          filebeat.inputs:
          - type: container
            paths:
              - /var/log/containers/*.log
            processors:
              - add_kubernetes_metadata:
                  host: $${NODE_NAME}
                  matchers:
                  - logs_path:
                      logs_path: "/var/log/containers/"
              - decode_json_fields:
                  fields: ["message"]
                  target: ""
                  overwrite_keys: true
                  add_error_key: true

          output.elasticsearch:
            hosts: ["http://elasticsearch-master:9200"]
            index: "filebeat-%{+yyyy.MM.dd}"

          setup.template:
            name: filebeat
            pattern: filebeat-*

          setup.ilm:
            enabled: true
            rollover_alias: filebeat
            pattern: "{now/d}-000001"
            policy_name: filebeat-policy

          processors:
            - add_cloud_metadata: ~
            - add_host_metadata: ~
        EOT
      }

      # DaemonSet resources
      resources = {
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }
        limits = {
          cpu    = "500m"
          memory = "256Mi"
        }
      }

      # Tolerations to run on all nodes
      tolerations = [
        {
          key      = "node-role.kubernetes.io/master"
          operator = "Exists"
          effect   = "NoSchedule"
        }
      ]
    })
  ]

  depends_on = [helm_release.elasticsearch]
}

# -----------------------------------------------------------------------------
# Jaeger (Distributed Tracing)
# -----------------------------------------------------------------------------
resource "helm_release" "jaeger" {
  count = var.enable_jaeger ? 1 : 0

  name       = "jaeger"
  repository = "https://jaegertracing.github.io/helm-charts"
  chart      = "jaeger"
  version    = var.jaeger_version
  namespace  = kubernetes_namespace.logging.metadata[0].name

  values = [
    yamlencode({
      # Production storage (Elasticsearch)
      provisionDataStore = {
        cassandra = false
        elasticsearch = false  # Using external ES
      }

      storage = {
        type = "elasticsearch"
        elasticsearch = {
          host = "elasticsearch-master"
          port = 9200
        }
      }

      # Collector
      collector = {
        replicaCount = var.jaeger_collector_replicas
        resources = {
          requests = {
            cpu    = "200m"
            memory = "256Mi"
          }
          limits = {
            cpu    = "1000m"
            memory = "512Mi"
          }
        }
      }

      # Query service
      query = {
        replicaCount = 1
        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "256Mi"
          }
        }
        service = {
          type = var.jaeger_service_type
        }
        ingress = {
          enabled = var.enable_ingress
          hosts   = [var.jaeger_host]
          tls = var.enable_tls ? [
            {
              secretName = "jaeger-tls"
              hosts      = [var.jaeger_host]
            }
          ] : []
        }
      }

      # Agent (sidecar)
      agent = {
        enabled = true
      }
    })
  ]

  depends_on = [helm_release.elasticsearch]
}

# -----------------------------------------------------------------------------
# Index Lifecycle Policy
# -----------------------------------------------------------------------------
resource "kubernetes_job" "setup_ilm_policy" {
  metadata {
    name      = "setup-ilm-policy"
    namespace = kubernetes_namespace.logging.metadata[0].name
  }

  spec {
    template {
      metadata {
        name = "setup-ilm-policy"
      }
      spec {
        container {
          name  = "setup"
          image = "curlimages/curl:latest"
          command = ["/bin/sh", "-c"]
          args = [<<-EOT
            # Wait for Elasticsearch
            until curl -s http://elasticsearch-master:9200/_cluster/health | grep -q '"status":"green"\|"status":"yellow"'; do
              echo "Waiting for Elasticsearch..."
              sleep 5
            done

            # Create ILM policy for logs
            curl -X PUT "http://elasticsearch-master:9200/_ilm/policy/logs-policy" \
              -H 'Content-Type: application/json' \
              -d '{
                "policy": {
                  "phases": {
                    "hot": {
                      "min_age": "0ms",
                      "actions": {
                        "rollover": {
                          "max_size": "10gb",
                          "max_age": "1d"
                        }
                      }
                    },
                    "warm": {
                      "min_age": "7d",
                      "actions": {
                        "shrink": {
                          "number_of_shards": 1
                        },
                        "forcemerge": {
                          "max_num_segments": 1
                        }
                      }
                    },
                    "cold": {
                      "min_age": "30d",
                      "actions": {
                        "freeze": {}
                      }
                    },
                    "delete": {
                      "min_age": "${var.log_retention_days}d",
                      "actions": {
                        "delete": {}
                      }
                    }
                  }
                }
              }'

            echo "ILM policy created successfully"
          EOT
          ]
        }
        restart_policy = "OnFailure"
      }
    }
    backoff_limit = 3
  }

  depends_on = [helm_release.elasticsearch]
}
