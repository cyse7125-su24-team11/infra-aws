# infra-aws

sudo touch /.VolumeIcon.icns


terraform apply --auto-approve -var helm_repo_token=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 -var "docker_config_content=$(cat /Users/shabinasingh/.docker/config.json)"


terraform apply --auto-approve -var helm_repo_token= -var username=poojary.m@northeastern.edu -var password= -var aws_cred=/Users/shabinasingh/.aws/credentials -var pg_username=postgres -var pg_password=postgres


helm upgrade --install fluent-bit fluent/fluent-bit

helm repo add fluent https://fluent.github.io/helm-charts
helm repo add jetstack https://charts.jetstack.io --force-update
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

curl -L https://istio.io/downloadIstio | sh -
cd istio-1.x.x
export PATH=$PWD/bin:$PATH
istioctl version
istioctl install --set profile=default -y
istioctl install -f modules/service_mesh/custom-profile.yaml -y 



kubectl port-forward -n monitoring svc/prometheus-server 9090:80

kubectl port-forward -n monitoring svc/grafana 3000:80



