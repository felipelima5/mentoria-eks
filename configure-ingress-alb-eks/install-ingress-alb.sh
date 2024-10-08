#!/bin/bash

export CLUSTER_NAME=eks-teste
export REGION=us-east-2
export ACCOUNT_ID=111109532426

export oidc_id=$(aws eks describe-cluster --region $REGION --name $CLUSTER_NAME --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)

echo "eksctl utils associate-iam-oidc-provider --region $REGION --cluster $CLUSTER_NAME --approve"
eksctl utils associate-iam-oidc-provider --region $REGION --cluster $CLUSTER_NAME --approve

echo "aws iam list-open-id-connect-providers | grep $oidc_id"
aws iam list-open-id-connect-providers | grep $oidc_id    

echo "finish create oidc id !!!"
echo "--------------------------------------------------------------------------------------------------------------------------------"



curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json

aws iam create-policy --region $REGION \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json


echo "Finish create policy !!! ----------------------------------------------------------------------------------------------------------------"


echo "eksctl create iamserviceaccount --region $REGION "

#kubectl delete sa aws-load-balancer-controller -n kube-system

eksctl create iamserviceaccount --region $REGION \
  --cluster=$CLUSTER_NAME \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::$ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve

echo "Finish create IAM service Account !!! ---------------------------------------------------------------------------------------------------"


kubectl apply \
    --validate=false \
    -f https://github.com/jetstack/cert-manager/releases/download/v1.12.3/cert-manager.yaml


echo "Finish create cert manager ---------------------------------------------------------------------------------------------------------------"



curl -Lo v2_5_4_full.yaml https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.5.4/v2_5_4_full.yaml

sed -i.bak -e '596,604d' ./v2_5_4_full.yaml

sed -i.bak -e 's|your-cluster-name|eks-teste|' ./v2_5_4_full.yaml


echo "kubectl apply -f v2_5_4_full.yaml ------------------------------------------- "
kubectl apply -f v2_5_4_full.yaml

curl -Lo v2_5_4_ingclass.yaml https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.5.4/v2_5_4_ingclass.yaml

kubectl apply -f v2_5_4_ingclass.yaml
