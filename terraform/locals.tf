locals {
  resource_prefix = "jobzy-${var.environment}"

  common_labels = merge(
    var.labels,
    {
      "environment" = var.environment
      "cluster"     = var.cluster_name
    }
  )

  kong_namespace     = "kong-system"
  keycloak_namespace = "keycloak"

  database_name = "jobzy_${replace(var.environment, "-", "_")}"
}
