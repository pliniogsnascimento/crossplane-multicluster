create-all: create-cluster install-crossplane configure-aws

create-cluster:
	kind create cluster --config=k8s/kind/config.yaml

delete-cluster:
	# kind delete cluster --name=$(cat ./kind/config.yaml |grep name |awk '{print $$2}')
	kind delete cluster --name=crossplane-cluster

install-crossplane:
	kubectl create namespace upbound-system

	# Using Upbound instead of crossplane
	helm repo add upbound-stable https://charts.upbound.io/stable
	helm repo update

	helm install uxp --namespace upbound-system upbound-stable/universal-crossplane --devel
	kubectl wait --for=condition=Available=true deployment/crossplane --timeout=60s -n=upbound-system

configure-aws:
	./scripts/get-aws-creds.sh
	kubectl create secret generic aws-creds -n upbound-system --from-file=creds=./creds.conf || true

	kubectl apply -f ./k8s/aws/provider/provider.yaml
	kubectl wait --for=condition=Healthy=true providers.pkg.crossplane.io/provider-family-aws --timeout=5m
	kubectl wait --for=condition=Healthy=true providers.pkg.crossplane.io/provider-aws-s3 --timeout=5m
	kubectl apply -f ./k8s/aws/provider/provider-config.yaml

deploy-eks:
	kubectl apply -f ./k8s/aws/eks/MRs/eks.yaml
	kubectl wait --for=condition=Available=true cluster.eks.aws.crossplane.io/crossplane-cluster --timeout=15m
	
	kg cluster.eks.aws.crossplane.io/crossplane-cluster -ojsonpath={.status.atProvider}
	kg cluster.eks.aws.crossplane.io/crossplane-cluster -ojsonpath={.status.atProvider.certificateAuthorityData}
	kg cluster.eks.aws.crossplane.io/crossplane-cluster -ojsonpath={.status.atProvider.identity.oidc.issuer}