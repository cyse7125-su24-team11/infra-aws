#!/bin/bash

echo "####################"
echo "Destroying Grafana "
echo "####################"

terraform -chdir=./modules/addons/grafana destroy --auto-approve -var-file=values.tfvars 

echo "####################"
echo "Applying Cert Manager "
echo "####################"

terraform -chdir=./modules/addons/certmanager destroy --auto-approve

echo "####################"
echo "Destroying Prometheus "
echo "####################"

terraform -chdir=./modules/addons/prometheus destroy --auto-approve -var-file=values.tfvars

echo "#################"
echo "Destroying Kafka "
echo "#################"

terraform -chdir=./modules/kafka destroy --auto-approve 


echo "#################"
echo "Destroying ISTIO "
echo "#################"

terraform -chdir=./modules/service_mesh destroy --auto-approve



echo "#####################"
echo "Destroying EksCluster "
echo "#####################"

terraform destroy --auto-approve -var-file=values.tfvars || true
