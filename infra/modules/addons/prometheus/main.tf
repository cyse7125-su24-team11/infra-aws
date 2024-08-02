

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace
    # labels = {
    #   "istio-injection" = "enabled"
    # }
  }
}

resource "kubernetes_network_policy" "allow_all_ingress" {
  metadata {
    name      = "allow-all-ingress"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  spec {
    pod_selector {}

    policy_types = ["Ingress"]

    ingress {
      # Omitting the 'from' field allows all ingress traffic
    }
  }
}

resource "helm_release" "prometheus" {
  name       = "prometheus"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"

  values = [
    <<EOF
    fullnameOverride: prometheus
    alertmanager:
      enabled: true
    pushgateway:
      enabled: true
    server:
      enabled: true
      service:
        type: ClusterIP
        port:
          name: http
          port: 80
          targetPort: ${var.prometheus_port}
    serverFiles:
      prometheus.yml:
        scrape_configs:
          - job_name: 'kafka_exporter'
            static_configs:
              - targets: ['kafka-exporter-prometheus-kafka-exporter.${var.namespace}.svc.cluster.local:${var.kafka_exporter_port}']
          - job_name: 'postgres_exporter'
            static_configs:
              - targets: ['postgres-exporter-prometheus-postgres-exporter.${var.namespace}.svc.cluster.local:80']
          - job_name: 'kube-state-metrics'
            static_configs:
              - targets: ['kube-state-metrics.${var.namespace}.svc.cluster.local:8080']
          - job_name: 'node-exporter'
            static_configs:
              - targets: ['node-exporter-prometheus-node-exporter.${var.namespace}.svc.cluster.local:${var.node_exporter_port}']
    EOF
  ]
}

resource "helm_release" "prometheus_operator" {
  name       = "prometheus-operator"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
#   version    = "latest"

  values = [
    <<EOF
    prometheus-node-exporter:
      service:
        port: ${var.prometheus_operator_node_exporter_port}
      tolerations:
        - key: "node-role.kubernetes.io/master"
          operator: "Exists"
          effect: "NoSchedule"
      prometheus:
        monitor:
          enabled: true
      resources:
        requests:
          memory: "64Mi"
          cpu: "100m"
        limits:
          memory: "128Mi"
          cpu: "200m"
    EOF
  ]
}

variable "prometheus_operator_node_exporter_port" {
  default = 9102  
}


resource "helm_release" "kafka_exporter" {
  name       = "kafka-exporter"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-kafka-exporter"
  values = [
<<EOF
    kafkaServer:
        - "kafka-broker-0-external.kafka-ns:${var.kafka_broker_port}"
    EOF
  ]
}

resource "helm_release" "postgres_exporter" {
  name       = "postgres-exporter"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-postgres-exporter"

  values = [
    <<EOF
    postgres:
      datasource:
        host: "postgres.consumer"
        port: "${var.postgres_port}"
        user: "${var.pg_username}"
        password: "${var.pg_password}"
        database: "cve"
    EOF
  ]
}

resource "helm_release" "kube_state_metrics" {
  name       = "kube-state-metrics"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-state-metrics"

  values = []
}

resource "helm_release" "node_exporter" {
  name       = "node-exporter"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-node-exporter"

  values = [
    <<EOF
    tolerations:
      - key: "node-role.kubernetes.io/master"
        operator: "Exists"
        effect: "NoSchedule"

    service:
      port: ${var.node_exporter_port}
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "${var.node_exporter_port}"

    # Set additional values if necessary
    resources:
      requests:
        memory: "64Mi"
        cpu: "100m"
      limits:
        memory: "128Mi"
        cpu: "200m"
    prometheus:
      monitor:
        enabled: true
    EOF
  ]
}

resource "helm_release" "grafana" {
  name       = "grafana"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"

  values = [
    <<EOF
    adminUser: "admin"
    adminPassword: "admin"
    datasources:
      datasources.yaml:
        apiVersion: 1
        datasources:
          - name: Prometheus
            type: prometheus
            url: "http://prometheus-server.${var.namespace}.svc.cluster.local:80"
            access: proxy
            isDefault: true
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
        kafka:
          gnetId: 7589
          revision: 1
          datasource: Prometheus
        postgres:
          gnetId: 9628
          revision: 1
          datasource: Prometheus
        node_exporter:
          gnetId: 1860
          revision: 37
          datasource: Prometheus
        kube_state_metrics:
          gnetId: 13332
          revision: 12
          datasource: Prometheus
    EOF
  ]
}

resource "kubernetes_manifest" "prometheus_virtualservice" {
  manifest = {
    apiVersion = "networking.istio.io/v1alpha3"
    kind       = "VirtualService"
    metadata = {
      name      = "prometheus-virtualservice"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
    }
    spec = {
      hosts = ["prometheus-server.${var.namespace}.svc.cluster.local"]
      http = [
        {
          route = [
            {
              destination = {
                host = "prometheus-server.${var.namespace}.svc.cluster.local"
                port = {
                  number = "${var.prometheus_port}"
                }
              }
            }
          ]
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "prometheus_serviceentry" {
  manifest = {
    apiVersion = "networking.istio.io/v1alpha3"
    kind       = "ServiceEntry"
    metadata = {
      name      = "prometheus-serviceentry"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
    }
    spec = {
      hosts = ["prometheus.${var.namespace}.svc.cluster.local"]
      ports = [
        {
          number   = "${var.prometheus_port}"
          name     = "http"
          protocol = "HTTP"
        }
      ]
      resolution = "DNS"
      location   = "MESH_INTERNAL"
      endpoints  = [
        {
          address = "prometheus.${var.namespace}.svc.cluster.local"
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "grafana_virtualservice" {
  manifest = {
    apiVersion = "networking.istio.io/v1alpha3"
    kind       = "VirtualService"
    metadata = {
      name      = "grafana-virtualservice"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
    }
    spec = {
      hosts = ["grafana.${var.namespace}.svc.cluster.local"]
      http = [
        {
          route = [
            {
              destination = {
                host = "grafana.${var.namespace}.svc.cluster.local"
                port = {
                  number = "${var.grafana_port}"
                }
              }
            }
          ]
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "grafana_serviceentry" {
  manifest = {
    apiVersion = "networking.istio.io/v1alpha3"
    kind       = "ServiceEntry"
    metadata = {
      name      = "grafana-serviceentry"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
    }
    spec = {
      hosts = ["grafana.${var.namespace}.svc.cluster.local"]
      ports = [
        {
          number   = "${var.grafana_port}"
          name     = "http"
          protocol = "HTTP"
        }
      ]
      resolution = "DNS"
      location   = "MESH_INTERNAL"
      endpoints  = [
        {
          address = "grafana.${var.namespace}.svc.cluster.local"
        }
      ]
    }
  }
}