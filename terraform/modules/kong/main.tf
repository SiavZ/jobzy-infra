resource "kubernetes_namespace" "kong" {
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

resource "kubernetes_secret" "kong_postgres" {
  metadata {
    name      = "kong-postgres-secret"
    namespace = kubernetes_namespace.kong.metadata[0].name
  }

  data = {
    username = var.db_user
    password = var.db_password
  }

  type = "Opaque"
}

resource "kubernetes_config_map" "kong_config" {
  metadata {
    name      = "kong-config"
    namespace = kubernetes_namespace.kong.metadata[0].name
  }

  data = {
    KONG_DATABASE         = "postgres"
    KONG_PG_HOST          = var.db_host
    KONG_PG_PORT          = tostring(var.db_port)
    KONG_PG_DATABASE      = var.db_name
    KONG_PROXY_ACCESS_LOG = "/dev/stdout"
    KONG_ADMIN_ACCESS_LOG = "/dev/stdout"
    KONG_PROXY_ERROR_LOG  = "/dev/stderr"
    KONG_ADMIN_ERROR_LOG  = "/dev/stderr"
    KONG_ADMIN_LISTEN     = "0.0.0.0:8001"
    KONG_PROXY_LISTEN     = "0.0.0.0:8000, 0.0.0.0:8443 ssl"
  }
}

resource "kubernetes_deployment" "kong" {
  metadata {
    name      = "kong"
    namespace = kubernetes_namespace.kong.metadata[0].name
    labels = merge(
      var.labels,
      {
        "app" = "kong"
      }
    )
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = "kong"
      }
    }

    template {
      metadata {
        labels = {
          app = "kong"
        }
      }

      spec {
        container {
          name  = "kong"
          image = "kong:${var.kong_version}"

          env {
            name = "KONG_PG_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.kong_postgres.metadata[0].name
                key  = "username"
              }
            }
          }

          env {
            name = "KONG_PG_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.kong_postgres.metadata[0].name
                key  = "password"
              }
            }
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.kong_config.metadata[0].name
            }
          }

          port {
            name           = "proxy"
            container_port = 8000
            protocol       = "TCP"
          }

          port {
            name           = "proxy-ssl"
            container_port = 8443
            protocol       = "TCP"
          }

          port {
            name           = "admin"
            container_port = 8001
            protocol       = "TCP"
          }

          liveness_probe {
            http_get {
              path = "/status"
              port = 8001
            }
            initial_delay_seconds = 60
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/status"
              port = 8001
            }
            initial_delay_seconds = 30
            period_seconds        = 5
          }

          resources {
            requests = {
              cpu    = "250m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "1000m"
              memory = "1Gi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "kong_proxy" {
  metadata {
    name      = "kong-proxy"
    namespace = kubernetes_namespace.kong.metadata[0].name
    labels = {
      app = "kong"
    }
  }

  spec {
    type = "LoadBalancer"

    selector = {
      app = "kong"
    }

    port {
      name        = "proxy"
      port        = 80
      target_port = 8000
      protocol    = "TCP"
    }

    port {
      name        = "proxy-ssl"
      port        = 443
      target_port = 8443
      protocol    = "TCP"
    }
  }
}

resource "kubernetes_service" "kong_admin" {
  metadata {
    name      = "kong-admin"
    namespace = kubernetes_namespace.kong.metadata[0].name
    labels = {
      app = "kong"
    }
  }

  spec {
    type = "ClusterIP"

    selector = {
      app = "kong"
    }

    port {
      name        = "admin"
      port        = 8001
      target_port = 8001
      protocol    = "TCP"
    }
  }
}
