#!/bin/bash

export ACCOUNT_ID=111109532426
export CLUSTER_NAME=eks-teste
export REGION=us-east-2

aws eks --region $REGION update-kubeconfig --name $CLUSTER_NAME

kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml

kubectl annotate serviceaccount cluster-autoscaler -n kube-system eks.amazonaws.com/role-arn=arn:aws:iam::$ACCOUNT_ID:role/system/AmazonEKSClusterAutoscalerRole

kubectl patch deployment cluster-autoscaler -n kube-system -p '{"spec":{"template":{"metadata":{"annotations":{"cluster-autoscaler.kubernetes.io/safe-to-evict": "false"}}}}}'

sed -i "s/<YOUR CLUSTER NAME>/eks-teste/g" cluster-autoscaler-autodiscover.yaml


kubectl -n kube-system logs -f deployment.apps/cluster-autoscaler
