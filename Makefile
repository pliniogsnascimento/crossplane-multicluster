create-all: create-cluster install-crossplane configure-aws

create-cluster:
	kind create cluster --config=k8s/kind/config.yaml

delete-cluster:
	# kind delete cluster --name=$(cat ./kind/config.yaml |grep name |awk '{print $$2}')
	kind delete cluster --name=crossplane-cluster

install-crossplane:
	kubectl create namespace crossplane-system

	helm repo add crossplane-stable https://charts.crossplane.io/stable
	helm repo update

	helm install crossplane --namespace crossplane-system crossplane-stable/crossplane --set args={'--debug'}
	kubectl wait --for=condition=Available=true deployment/crossplane --timeout=60s -n=crossplane-system

configure-aws:
	./scripts/get-aws-creds.sh
	kubectl create secret generic aws-creds -n crossplane-system --from-file=creds=./creds.conf || true

	kubectl apply -f ./k8s/aws/provider/provider.yaml
	kubectl wait --for=condition=Healthy=true provider.pkg.crossplane.io/provider-aws --timeout=5m
	kubectl apply -f ./k8s/aws/provider/provider-config.yaml

deploy-eks:
	kubectl apply -f ./k8s/aws/eks/MRs/eks.yaml
	kubectl wait --for=condition=Available=true cluster.eks.aws.crossplane.io/crossplane-cluster --timeout=15m
	
	kg cluster.eks.aws.crossplane.io/crossplane-cluster -ojsonpath={.status.atProvider}
	kg cluster.eks.aws.crossplane.io/crossplane-cluster -ojsonpath={.status.atProvider.certificateAuthorityData}
	kg cluster.eks.aws.crossplane.io/crossplane-cluster -ojsonpath={.status.atProvider.identity.oidc.issuer}