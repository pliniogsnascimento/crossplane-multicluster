create-all: create-cluster install-crossplane

create-cluster:
	kind create cluster --config=kind/config.yaml

delete-cluster:
	# kind delete cluster --name=$(cat ./kind/config.yaml |grep name |awk '{print $$2}')
	kind delete cluster --name=crossplane-cluster

install-crossplane:
	kubectl create namespace crossplane-system

	helm repo add crossplane-stable https://charts.crossplane.io/stable
	helm repo update

	helm install crossplane --namespace crossplane-system crossplane-stable/crossplane --set args={'--debug'}

configure-aws:
	./scripts/get-aws-creds.sh
	kubectl create secret generic aws-creds -n crossplane-system --from-file=creds=./creds.conf || true

	kubectl crossplane install configuration registry.upbound.io/xp/getting-started-with-aws:latest
	kubectl apply -f ./k8s/aws/provider