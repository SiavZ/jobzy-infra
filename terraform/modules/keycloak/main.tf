resource "kubernetes_namespace" "keycloak" {
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

resource "kubernetes_secret" "keycloak_postgres" {
  metadata {
    name      = "keycloak-postgres-secret"
    namespace = kubernetes_namespace.keycloak.metadata[0].name
  }

  data = {
    username = var.db_user
    password = var.db_password
  }

  type = "Opaque"
}

resource "kubernetes_secret" "keycloak_admin" {
  metadata {
    name      = "keycloak-admin-secret"
    namespace = kubernetes_namespace.keycloak.metadata[0].name
  }

  data = {
    username = "admin"
    password = var.admin_password
  }

  type = "Opaque"
}

resource "kubernetes_config_map" "keycloak_config" {
  metadata {
    name      = "keycloak-config"
    namespace = kubernetes_namespace.keycloak.metadata[0].name
  }

  data = {
    KC_DB                 = "postgres"
    KC_DB_URL_HOST        = var.db_host
    KC_DB_URL_PORT        = tostring(var.db_port)
    KC_DB_URL_DATABASE    = var.db_name
    KC_HOSTNAME           = var.hostname
    KC_PROXY              = "edge"
    KC_HEALTH_ENABLED     = "true"
    KC_METRICS_ENABLED    = "true"
    KC_HTTP_ENABLED       = "true"
    KC_HOSTNAME_STRICT    = "false"
    KEYCLOAK_LOGLEVEL     = "INFO"
    ROOT_LOGLEVEL         = "INFO"
  }
}

resource "kubernetes_deployment" "keycloak" {
  metadata {
    name      = "keycloak"
    namespace = kubernetes_namespace.keycloak.metadata[0].name
    labels = merge(
      var.labels,
      {
        "app" = "keycloak"
      }
    )
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = "keycloak"
      }
    }

    template {
      metadata {
        labels = {
          app = "keycloak"
        }
      }

      spec {
        container {
          name  = "keycloak"
          image = "quay.io/keycloak/keycloak:${var.keycloak_version}"
          args  = ["start"]

          env {
            name = "KC_DB_USERNAME"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.keycloak_postgres.metadata[0].name
                key  = "username"
              }
            }
          }

          env {
            name = "KC_DB_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.keycloak_postgres.metadata[0].name
                key  = "password"
              }
            }
          }

          env {
            name = "KEYCLOAK_ADMIN"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.keycloak_admin.metadata[0].name
                key  = "username"
              }
            }
          }

          env {
            name = "KEYCLOAK_ADMIN_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.keycloak_admin.metadata[0].name
                key  = "password"
              }
            }
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.keycloak_config.metadata[0].name
            }
          }

          port {
            name           = "http"
            container_port = 8080
            protocol       = "TCP"
          }

          port {
            name           = "https"
            container_port = 8443
            protocol       = "TCP"
          }

          liveness_probe {
            http_get {
              path = "/health/live"
              port = 8080
            }
            initial_delay_seconds = 120
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/health/ready"
              port = 8080
            }
            initial_delay_seconds = 60
            period_seconds        = 5
          }

          resources {
            requests = {
              cpu    = "500m"
              memory = "1Gi"
            }
            limits = {
              cpu    = "2000m"
              memory = "2Gi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "keycloak" {
  metadata {
    name      = "keycloak"
    namespace = kubernetes_namespace.keycloak.metadata[0].name
    labels = {
      app = "keycloak"
    }
  }

  spec {
    type = "LoadBalancer"

    selector = {
      app = "keycloak"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 8080
      protocol    = "TCP"
    }

    port {
      name        = "https"
      port        = 443
      target_port = 8443
      protocol    = "TCP"
    }
  }
}
