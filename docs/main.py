from urllib.request import urlretrieve

from diagrams import Cluster, Diagram, Edge
from diagrams.aws.compute import EKS
from diagrams.gcp.compute import GKE
from diagrams.custom import Custom
from diagrams.azure.compute import AKS
from diagrams.onprem.network import Istio
from diagrams.k8s.compute import Deployment
from diagrams.onprem.gitops import ArgoCD

crossplane_url = 'https://avatars.githubusercontent.com/u/45158470?s=200&v=4'
crossplane_icon = 'crossplane.png'
urlretrieve(crossplane_url, crossplane_icon)

kubevela_url = 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTlO6zkn0JBop-WQ5cpLOsO1rRIMvgZbFkDr8zZWSuLdWH4BV1SYW-dglEuTaSChLW8F6k&usqp=CAU'
kubevela_icon = 'kubevela.png'
urlretrieve(kubevela_url, kubevela_icon)

with Diagram("gitops-demo", show=False):
    source_cluster = EKS("controlplane-cluster")

    with Cluster("AWS"):
        eks_gitops = EKS("eks-gitops")
        istio_eks = Istio("Istio")
        argo_eks = ArgoCD("ArgoCD EKS")
        bookinfo_product_page = Deployment("Bookinfo product-page")
        kubevela = Custom("Kubevela", kubevela_icon)

        argo_eks  \
            - Edge(label="deploys") \
            >> kubevela \
            >> bookinfo_product_page \

        eks_gitops >> bookinfo_product_page >> istio_eks
    
    with Cluster("GCP"):
        gke_gitops = GKE("gke-gitops")
        istio_gke = Istio("Istio")
        argo_gke = ArgoCD("ArgoCD GKE")
        bookinfo_details = Deployment("Bookinfo details")

        argo_gke >> bookinfo_details
        gke_gitops >> bookinfo_details >> istio_gke
    
    with Cluster("Azure"):
        aks_gitops = AKS("aks-gitops")
        istio_aks = Istio("Istio")
        argo_aks = ArgoCD("ArgoCD AKS")
        bookinfo_ratings = Deployment("Bookinfo ratings")
        bookinfo_reviews = Deployment("Bookinfo reviews")

        argo_aks >> bookinfo_reviews
        argo_aks >> bookinfo_ratings
        aks_gitops >> bookinfo_reviews >> istio_aks
        aks_gitops >> bookinfo_ratings >> istio_aks


    crossplane = Custom("Crossplane", crossplane_icon)
    
    source_cluster >> crossplane >> eks_gitops
    crossplane >> gke_gitops
    crossplane >> aks_gitops

    istio_aks >> istio_eks
    istio_aks >> istio_gke
    istio_eks >> istio_aks
    istio_eks >> istio_gke
    istio_gke >> istio_eks
    istio_gke >> istio_aks
    
