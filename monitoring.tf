resource "helm_release" "prometheus" {
  name             = "prometheus-${var.environment}"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "67.4.0"
  namespace        = "monitoring"
  create_namespace = true

  values = [
    <<-EOT
    prometheus:
      prometheusSpec:
        serviceMonitorSelectorNilUsesHelmValues: false
        serviceMonitorNamespaceSelector: {}
        serviceMonitorSelector: {}
        retention: 15d
        resources:
          requests:
            cpu: 200m
            memory: 512Mi
          limits:
            cpu: 500m
            memory: 1Gi
        storageSpec:
          volumeClaimTemplate:
            spec:
              accessModes: ["ReadWriteOnce"]
              resources:
                requests:
                  storage: 10Gi

    grafana:
      persistence:
        enabled: true
        size: 5Gi

      dashboardProviders:
        dashboardproviders.yaml:
          apiVersion: 1
          providers:
          - name: 'default'
            orgId: 1
            folder: ''
            type: file
            disableDeletion: false
            editable: true
            options:
              path: /var/lib/grafana/dashboards/default

      dashboards:
        default:
          api-metrics:
            json: |
              {
                "annotations": {
                  "list": []
                },
                "editable": true,
                "fiscalYearStartMonth": 0,
                "graphTooltip": 0,
                "hideControls": false,
                "links": [],
                "liveNow": false,
                "panels": [
                  {
                    "datasource": {
                      "type": "prometheus",
                      "uid": "prometheus"
                    },
                    "fieldConfig": {
                      "defaults": {
                        "color": {
                          "mode": "palette-classic"
                        },
                        "custom": {
                          "axisCenteredZero": false,
                          "axisColorMode": "text",
                          "axisLabel": "",
                          "axisPlacement": "auto",
                          "barAlignment": 0,
                          "drawStyle": "line",
                          "fillOpacity": 10,
                          "gradientMode": "none",
                          "hideFrom": {
                            "legend": false,
                            "tooltip": false,
                            "viz": false
                          },
                          "lineInterpolation": "linear",
                          "lineWidth": 1,
                          "pointSize": 5,
                          "scaleDistribution": {
                            "type": "linear"
                          },
                          "showPoints": "never",
                          "spanNulls": false,
                          "stacking": {
                            "group": "A",
                            "mode": "none"
                          },
                          "thresholdsStyle": {
                            "mode": "off"
                          }
                        },
                        "mappings": [],
                        "thresholds": {
                          "mode": "absolute",
                          "steps": [
                            {
                              "color": "green",
                              "value": null
                            }
                          ]
                        },
                        "unit": "short"
                      },
                      "overrides": []
                    },
                    "gridPos": {
                      "h": 8,
                      "w": 12,
                      "x": 0,
                      "y": 0
                    },
                    "id": 1,
                    "options": {
                      "legend": {
                        "calcs": [],
                        "displayMode": "list",
                        "placement": "bottom",
                        "showLegend": true
                      },
                      "tooltip": {
                        "mode": "single",
                        "sort": "none"
                      }
                    },
                    "targets": [
                      {
                        "datasource": {
                          "type": "prometheus",
                          "uid": "prometheus"
                        },
                        "expr": "rate(http_requests_total[5m])",
                        "refId": "A"
                      }
                    ],
                    "title": "HTTP Request Rate",
                    "type": "timeseries"
                  }
                ],
                "refresh": "5s",
                "schemaVersion": 38,
                "style": "dark",
                "tags": ["api"],
                "templating": {
                  "list": []
                },
                "time": {
                  "from": "now-6h",
                  "to": "now"
                },
                "timepicker": {},
                "timezone": "browser",
                "title": "API Metrics Dashboard",
                "version": 0
              }

    alertmanager:
      enabled: true
      config:
        route:
          group_by: ['job']
          group_wait: 30s
          group_interval: 5m
          repeat_interval: 12h
          receiver: 'null'
        receivers:
        - name: 'null'

    nodeExporter:
      enabled: true

    kubeStateMetrics:
      enabled: true
    EOT
  ]
}

resource "kubernetes_manifest" "api_service_monitor" {
  depends_on = [helm_release.prometheus]

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "api-${var.environment}"
      namespace = "monitoring"
      labels = {
        release = "prometheus-${var.environment}"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          app = "api-${var.environment}-api"
        }
      }
      endpoints = [
        {
          port = "http"
          path = "/metrics"
        }
      ]
    }
  }
}
