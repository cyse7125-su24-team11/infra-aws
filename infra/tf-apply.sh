#!/bin/bash


echo "#####################"
echo "Deploying EksCluster "
echo "#####################"

terraform init
terraform apply --auto-approve -var-file=values.tfvars


echo "################"
echo "Applying ISTIO "
echo "################"

terraform -chdir=./modules/service_mesh init
terraform -chdir=./modules/service_mesh apply --auto-approve || exit 1


echo "###############"
echo "Applying Kafka "
echo "###############"

terraform -chdir=./modules/kafka init
terraform -chdir=./modules/kafka apply --auto-approve


echo "####################"
echo "Applying Prometheus "
echo "####################"


terraform -chdir=./modules/addons/prometheus init
terraform -chdir=./modules/addons/prometheus apply --auto-approve -var-file=values.tfvars



echo "####################"
echo "Applying Cert Manager "
echo "####################"


terraform -chdir=./modules/addons/certmanager init
terraform -chdir=./modules/addons/certmanager apply --auto-approve


echo "####################"
echo "Applying Grafana "
echo "####################"


terraform -chdir=./modules/addons/grafana init
terraform -chdir=./modules/addons/grafana apply --auto-approve -var-file=values.tfvars

