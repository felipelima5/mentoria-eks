# k8s-configure-cluster

### Criar um provedor de OIDC para o seu Cluster
```
cluster_name=app-prod
oidc_id=$(aws eks describe-cluster --region us-east-1 --name $cluster_name --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)
```

```
aws iam list-open-id-connect-providers | grep $oidc_id    
```


### Se nenhum resultado for retornado no comando acima, execute o comando abaixo !
```
eksctl utils associate-iam-oidc-provider --region us-east-1 --cluster $cluster_name --approve
```

# Instale o Kubectx e Kubens
```
#!/bin/bash
git clone https://github.com/ahmetb/kubectx /opt/kubectx
ln -s /opt/kubectx/kubens /usr/local/bin/kubens
```

# Instale o eksctl 

```
# for ARM systems, set ARCH to: `arm64`, `armv6` or `armv7`
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH

curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
curl -sL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_checksums.txt" | grep $PLATFORM | sha256sum --check
tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz

sudo mv /tmp/eksctl /usr/local/bin
```

# Adicione as Tags obrigatórias nas Subnets

### Tag Obrigatoria em todas
kubernetes.io/cluster/my-cluster = shared

### Inserir essa nas subnets privadas caso o ELB do Ingress seja privado
kubernetes.io/role/internal-elb = 1

### Inserir essa nas subnets publicas caso o ELB do Ingress seja publico
kubernetes.io/role/elb = 1




# Instale o AWS LoadBalancer Controller

### Baixe a Politica com as Permissões necessárias
```
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json
```

### Crie a Política através do AWS IAM
```
aws iam create-policy --region us-east-1 \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json
```

### Crie um service Account para o AWS LoadBalancer Controller
```
eksctl create iamserviceaccount --region us-east-1 \
  --cluster=app-prod \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::XXXXXXXXXXX:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve
```


### Instale o CertManager
```
kubectl apply \
    --validate=false \
    -f https://github.com/jetstack/cert-manager/releases/download/v1.12.3/cert-manager.yaml
```

### Baixe o Instalador do AWS LoadBalancer Controller
```
curl -Lo v2_5_4_full.yaml https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.5.4/v2_5_4_full.yaml
```


### Comente/Remova o Trecho do Service Account (isso serve para que o Service Account criado acima não seja substituído)

### Trecho a ser comentado/removido
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/name: aws-load-balancer-controller
  name: aws-load-balancer-controller
  namespace: kube-system

### Execute o comando para comentar/remover
```
sed -i.bak -e '596,604d' ./v2_5_4_full.yaml
```


### Substitua your-cluster-name na seção Deployment spec do arquivo pelo nome do cluster substituindo my-cluster pelo nome do seu cluster.
```
sed -i.bak -e 's|your-cluster-name|my-cluster|' ./v2_5_4_full.yaml
```


### Aplique o manifesto ao seu cluster
```
kubectl apply -f v2_5_4_full.yaml
```


### Baixe os manifestos IngressClass e IngressClassParams para seu cluster.
```
curl -Lo v2_5_4_ingclass.yaml https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.5.4/v2_5_4_ingclass.yaml
```

### Aplique o manifesto IngressClass ao seu cluster
```
kubectl apply -f v2_5_4_ingclass.yaml

```









