# =============================================================================
# Observability Stack Module for Jobzy Platform
# =============================================================================
# Deploys monitoring infrastructure using Helm:
# - Prometheus (metrics collection)
# - Grafana (visualization & dashboards)
# - AlertManager (alerting)
# =============================================================================

# -----------------------------------------------------------------------------
# Namespace
# -----------------------------------------------------------------------------
resource "kubernetes_namespace" "monitoring" {
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
# Prometheus Stack (kube-prometheus-stack Helm chart)
# -----------------------------------------------------------------------------
resource "helm_release" "prometheus_stack" {
  name       = "prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.prometheus_stack_version
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    yamlencode({
      # Global settings
      defaultRules = {
        create = true
        rules = {
          alertmanager                = true
          etcd                        = false  # Not accessible in GKE
          configReloaders             = true
          general                     = true
          k8s                         = true
          kubeApiserver               = true
          kubeApiserverAvailability   = true
          kubeApiserverSlos           = true
          kubelet                     = true
          kubeProxy                   = false  # Not accessible in GKE
          kubePrometheusGeneral       = true
          kubePrometheusNodeRecording = true
          kubernetesApps              = true
          kubernetesResources         = true
          kubernetesStorage           = true
          kubernetesSystem            = true
          kubeScheduler               = false  # Not accessible in GKE
          kubeStateMetrics            = true
          network                     = true
          node                        = true
          nodeExporterAlerting        = true
          nodeExporterRecording       = true
          prometheus                  = true
          prometheusOperator          = true
        }
      }

      # Prometheus configuration
      prometheus = {
        prometheusSpec = {
          retention         = var.prometheus_retention
          retentionSize     = var.prometheus_retention_size
          scrapeInterval    = "15s"
          evaluationInterval = "15s"

          resources = {
            requests = {
              cpu    = "500m"
              memory = "1Gi"
            }
            limits = {
              cpu    = "2000m"
              memory = "4Gi"
            }
          }

          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = var.storage_class
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = var.prometheus_storage_size
                  }
                }
              }
            }
          }

          # Service monitors for Jobzy services
          additionalScrapeConfigs = [
            {
              job_name = "jobzy-services"
              kubernetes_sd_configs = [
                {
                  role = "pod"
                  namespaces = {
                    names = var.monitored_namespaces
                  }
                }
              ]
              relabel_configs = [
                {
                  source_labels = ["__meta_kubernetes_pod_annotation_prometheus_io_scrape"]
                  action        = "keep"
                  regex         = "true"
                },
                {
                  source_labels = ["__meta_kubernetes_pod_annotation_prometheus_io_path"]
                  action        = "replace"
                  target_label  = "__metrics_path__"
                  regex         = "(.+)"
                },
                {
                  source_labels = ["__address__", "__meta_kubernetes_pod_annotation_prometheus_io_port"]
                  action        = "replace"
                  regex         = "([^:]+)(?::\\d+)?;(\\d+)"
                  replacement   = "$1:$2"
                  target_label  = "__address__"
                },
                {
                  action       = "labelmap"
                  regex        = "__meta_kubernetes_pod_label_(.+)"
                },
                {
                  source_labels = ["__meta_kubernetes_namespace"]
                  action        = "replace"
                  target_label  = "kubernetes_namespace"
                },
                {
                  source_labels = ["__meta_kubernetes_pod_name"]
                  action        = "replace"
                  target_label  = "kubernetes_pod_name"
                }
              ]
            }
          ]
        }
      }

      # Grafana configuration
      grafana = {
        enabled       = true
        adminPassword = var.grafana_admin_password

        persistence = {
          enabled          = true
          storageClassName = var.storage_class
          size             = "10Gi"
        }

        resources = {
          requests = {
            cpu    = "100m"
            memory = "256Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }

        service = {
          type = var.grafana_service_type
        }

        # Pre-configured datasources
        datasources = {
          "datasources.yaml" = {
            apiVersion = 1
            datasources = [
              {
                name      = "Prometheus"
                type      = "prometheus"
                url       = "http://prometheus-stack-prometheus:9090"
                access    = "proxy"
                isDefault = true
              }
            ]
          }
        }

        # Pre-configured dashboards
        dashboardProviders = {
          "dashboardproviders.yaml" = {
            apiVersion = 1
            providers = [
              {
                name            = "default"
                orgId           = 1
                folder          = ""
                type            = "file"
                disableDeletion = false
                editable        = true
                options = {
                  path = "/var/lib/grafana/dashboards/default"
                }
              }
            ]
          }
        }

        dashboards = {
          default = {
            kubernetes-cluster = {
              gnetId     = 7249
              revision   = 1
              datasource = "Prometheus"
            }
            nginx-ingress = {
              gnetId     = 9614
              revision   = 1
              datasource = "Prometheus"
            }
            node-exporter = {
              gnetId     = 1860
              revision   = 29
              datasource = "Prometheus"
            }
          }
        }

        ingress = {
          enabled = var.enable_ingress
          annotations = {
            "kubernetes.io/ingress.class" = "nginx"
          }
          hosts = var.grafana_hosts
          tls   = var.enable_tls ? [
            {
              secretName = "grafana-tls"
              hosts      = var.grafana_hosts
            }
          ] : []
        }
      }

      # AlertManager configuration
      alertmanager = {
        alertmanagerSpec = {
          storage = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = var.storage_class
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "5Gi"
                  }
                }
              }
            }
          }
        }

        config = {
          global = {
            resolve_timeout = "5m"
          }
          route = {
            group_by        = ["alertname", "namespace"]
            group_wait      = "30s"
            group_interval  = "5m"
            repeat_interval = "4h"
            receiver        = "default"
            routes = [
              {
                match = {
                  severity = "critical"
                }
                receiver = "critical"
              }
            ]
          }
          receivers = [
            {
              name = "default"
              slack_configs = var.slack_webhook_url != "" ? [
                {
                  api_url  = var.slack_webhook_url
                  channel  = var.slack_channel
                  username = "AlertManager"
                }
              ] : []
            },
            {
              name = "critical"
              slack_configs = var.slack_webhook_url != "" ? [
                {
                  api_url  = var.slack_webhook_url
                  channel  = var.slack_critical_channel
                  username = "AlertManager - CRITICAL"
                }
              ] : []
              pagerduty_configs = var.pagerduty_service_key != "" ? [
                {
                  service_key = var.pagerduty_service_key
                }
              ] : []
            }
          ]
        }
      }

      # Node exporter
      nodeExporter = {
        enabled = true
      }

      # Kube state metrics
      kubeStateMetrics = {
        enabled = true
      }

      # Prometheus Operator
      prometheusOperator = {
        enabled = true
      }
    })
  ]

  depends_on = [kubernetes_namespace.monitoring]
}

# -----------------------------------------------------------------------------
# Custom ServiceMonitors for Jobzy services
# -----------------------------------------------------------------------------
resource "kubernetes_manifest" "kong_service_monitor" {
  count = var.create_service_monitors ? 1 : 0

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "kong-monitor"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
      labels = {
        app     = "kong"
        release = "prometheus-stack"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          app = "kong"
        }
      }
      namespaceSelector = {
        matchNames = ["kong-system"]
      }
      endpoints = [
        {
          port     = "status"
          path     = "/metrics"
          interval = "15s"
        }
      ]
    }
  }

  depends_on = [helm_release.prometheus_stack]
}

resource "kubernetes_manifest" "keycloak_service_monitor" {
  count = var.create_service_monitors ? 1 : 0

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "keycloak-monitor"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
      labels = {
        app     = "keycloak"
        release = "prometheus-stack"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          app = "keycloak"
        }
      }
      namespaceSelector = {
        matchNames = ["keycloak"]
      }
      endpoints = [
        {
          port     = "http"
          path     = "/metrics"
          interval = "15s"
        }
      ]
    }
  }

  depends_on = [helm_release.prometheus_stack]
}
