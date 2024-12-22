resource "helm_release" "postgresql" {
  name       = "postgresql-${var.environment}"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"
  version    = "12.5.6"
  namespace  = "default"

  values = [
    <<-EOT
    global:
      postgresql:
        auth:
          postgresPassword: "${var.postgres_password}"
          username: "${var.postgres_username}"
          password: "${var.postgres_password}"
          database: "${var.postgres_database}"

    auth:
      postgresPassword: "${var.postgres_password}"
      username: "${var.postgres_username}"
      password: "${var.postgres_password}"
      database: "${var.postgres_database}"

    primary:
      persistence:
        enabled: true
        size: 1Gi

      extraEnvVars:
        - name: POSTGRESQL_ENABLE_TLS
          value: "no"
        - name: POSTGRES_PASSWORD
          value: "${var.postgres_password}"
    EOT
  ]
}

resource "helm_release" "api" {
  name       = "api-${var.environment}"
  chart      = "./helm/api"
  namespace  = "default"
  depends_on = [helm_release.postgresql]

  set {
    name  = "image.repository"
    value = var.api_image_repository
  }

  set {
    name  = "image.tag"
    value = var.api_image_tag
  }

  set {
    name  = "configmap.DATABASE_URL"
    value = "postgres://${var.postgres_username}:${var.postgres_password}@postgresql-${var.environment}:5432/${var.postgres_database}?sslmode=disable"
  }
}
