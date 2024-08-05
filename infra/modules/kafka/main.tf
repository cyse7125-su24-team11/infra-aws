
resource "random_id" "kafka_password" {
  byte_length = 8
}

data "aws_eks_cluster_auth" "cluster_auth" {
  name = var.eks_name
}

data "aws_eks_cluster" "eks_cluster" {
  name = var.eks_name
}


provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster_auth.token
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.eks_name, "--role-arn", data.aws_eks_cluster.eks_cluster.role_arn]
    command     = "aws"
  }
}


provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks_cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster_auth.token
  }
}
resource "null_resource" "update_kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks --region ${var.region} update-kubeconfig --name ${data.aws_eks_cluster.eks_cluster.name}"
  }
  depends_on = [data.aws_eks_cluster.eks_cluster]
}


resource "kubernetes_namespace" "kafka_ns" {
  metadata {
    name = "kafka-ns"
    labels = {
      "istio-injection" = "enabled"
    }
  }
  depends_on = [null_resource.update_kubeconfig]
}

resource "kubernetes_secret" "kafka" {
  metadata {
    name      = var.kafka_secret
    namespace = var.kafka_ns
  }

  data = {
    kafka-password = random_id.kafka_password.hex
  }
  depends_on = [null_resource.update_kubeconfig]
}


resource "kubernetes_storage_class" "ebs_sc" {
  metadata {
    name = var.ebs_sc
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  storage_provisioner = var.ebs_csi_provisioner
  parameters = {
    type = var.ebs_type
  }
  depends_on = [null_resource.update_kubeconfig]
}

data "aws_subnets" "private_subnets" {
  filter {
    name   = "tag:kubernetes.io/role/internal-elb"
    values = ["1"]
  }
}

resource "helm_release" "kafka" {
  name = var.kafka

  namespace  = var.kafka_ns
  repository = var.kafka_bitnami_repo
  # repository = "oci://registry-1.docker.io/bitnamicharts"
  chart   = var.kafka
  version = var.kafka_bitnami_version

  values = [
    <<EOF
broker:
  automountServiceAccountToken: true
  replicaCount: 1
  resources:
    requests:
      cpu: "500m"
      memory: "256Mi"
    limits:
      cpu: "500m"
      memory: "1024Mi"
  autoscaling:
    hpa:
      enabled: true
      minReplicas: 1
      maxReplicas: 4
      targetCPU: 90
controller:
  automountServiceAccountToken: true
  replicaCount: 1
  controllerOnly: true
  resources:
    requests:
      cpu: "200m"
      memory: "512Mi"
    limits:
      cpu: "500m"
      memory: "1024Mi"
kraft:
  enabled: true
  processRoles: broker,controller
zookeeper:
  enabled: false
metrics:
  jmx:
    enabled:true
pdb:
  create: true
  minAvailable: 1
provisioning:
  enabled: true
  automountServiceAccountToken: false
  topics:
  - name: push_cve_records
    replicationFactor: 1
    numPartitions: 6
  podAnnotations:
    sidecar.istio.io/inject: "false"
externalAccess:
  enabled: true
  autoDiscovery:
    enabled: true
  broker:
    ports:
      external: 9094
    automountServiceAccountToken: false
    readinessProbe:
      initialDelaySeconds: 30
    service:
      type: LoadBalancer
      allocateLoadBalancerNodePorts: true
      loadBalancerSourceRanges:
        - ${var.private_subnet_cidrs[0]}
        - ${var.private_subnet_cidrs[1]}
        - ${var.private_subnet_cidrs[2]}
      publishNotReadyAddresses: true
      loadBalancerAnnotations:
        "service.beta.kubernetes.io/aws-load-balancer-scheme": "internal"
        "service.beta.kubernetes.io/aws-load-balancer-subnets": "${join(",", data.aws_subnets.private_subnets.ids)}"
      annotations:
        "service.beta.kubernetes.io/aws-load-balancer-scheme": "internal"
        "service.beta.kubernetes.io/aws-load-balancer-subnets": "${join(",", data.aws_subnets.private_subnets.ids)}"
  controller:
    ports:
      external: 9093
    readinessProbe:
      initialDelaySeconds: 30
    service:
      type: LoadBalancer
      allocateLoadBalancerNodePorts: true
      automountServiceAccountToken: false
      publishNotReadyAddresses: true
      loadBalancerSourceRanges:  
        - ${var.private_subnet_cidrs[0]}
        - ${var.private_subnet_cidrs[1]}
        - ${var.private_subnet_cidrs[2]}
      loadBalancerAnnotations:
        "service.beta.kubernetes.io/aws-load-balancer-scheme": "internal"
        "service.beta.kubernetes.io/aws-load-balancer-subnets": "${join(",", data.aws_subnets.private_subnets.ids)}"
      annotations:
        "service.beta.kubernetes.io/aws-load-balancer-scheme": "internal"
        "service.beta.kubernetes.io/aws-load-balancer-subnets": "${join(",", data.aws_subnets.private_subnets.ids)}"
rbac:
  create: true
serviceAccount:
  create: true
  automountServiceAccountToken: false
listeners:
  client:
    containerPort: 9092
    protocol: PLAINTEXT
    name: CLIENT
    sslClientAuth: "required"
  controller:
    name: CONTROLLER
    containerPort: 9093
    protocol: PLAINTEXT
    sslClientAuth: "required"
  interbroker:
    containerPort: 9094
    protocol: PLAINTEXT
    name: INTERNAL
    sslClientAuth: "required"
  external:
    containerPort: 9095
    protocol: PLAINTEXT
    name: EXTERNAL
  securityProtocolMap: CLIENT:PLAINTEXT,CONTROLLER:PLAINTEXT,INTERNAL:PLAINTEXT,EXTERNAL:PLAINTEXT
  advertisedListeners: "CLIENT://kafka-broker-0-external.kafka-ns.svc.cluster.local:9094,INTERNAL://kafka-broker-0-external.kafka-ns.svc.cluster.local:9094,EXTERNAL://kafka-broker-0-external.kafka-ns.svc.cluster.local:9094"
metrics:
  jmx:
    enabled: true
extraConfig:
  defaultReplicationFactor: 1
  offsetsTopicReplicationFactor: 1
  maxMessageBytes: 10485880
  logFlushIntervalMessages: 1
    EOF
  ]
  depends_on = [null_resource.update_kubeconfig]

}

data "kubernetes_service" "kafka" {
  metadata {
    name      = var.kafka
    namespace = var.kafka_ns # Update with your Kafka namespace
  }
}

# locals {
#   bootstrap_servers = [
#     # for cluster_ip in data.kubernetes_service.kafka.spec.cluster_ip : "${cluster_ip}:9092"
#   ]
# }


# provider "kafka" {
#   bootstrap_servers = ["${data.kubernetes_service.kafka.spec[0].load_balancer_ip}:9092"]
#   # bootstrap_servers = module.kafka.bootstrap_servers
# }

# resource "kafka_topic" "push_cve_records" {
#   name               = var.push_cve_records
#   replication_factor = var.topic_replication_factor
#   partitions         = var.topic_partitions

#   config = {
#     "cleanup.policy" = var.topic_cleanup_policy
#     "segment.ms"     = var.topic_segment
#     "retention.ms"   = var.topic_retention
#   }
# }



resource "kubernetes_manifest" "kafka_virtualservice" {
  manifest = {
    apiVersion = "networking.istio.io/v1alpha3"
    kind       = "VirtualService"
    metadata = {
      name      = "kafka-virtualservice"
      namespace = kubernetes_namespace.kafka_ns.metadata[0].name
    }
    spec = {
      hosts = ["kafka-broker-0-external.kafka-ns.svc.cluster.local"]
      tcp = [{
        match = [{
          port = 9094
        }]
        route = [{
          destination = {
            host = "kafka-broker-0-external.kafka-ns.svc.cluster.local"
            port = {
              number = 9094 
            }
          }
        }]
      }]
    }
  }
}