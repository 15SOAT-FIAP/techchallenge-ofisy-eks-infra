# Tech Challenge — Infraestrutura Kubernetes (AWS EKS & Redes via Terraform)

Repositório dedicado ao provisionamento infraestrutural base da aplicação **Ofisy** na AWS para a **Fase 3 do Tech Challenge SOAT (FIAP)**, englobando a rede (VPC, Subnets, Internet Gateway, NAT Gateway), o cluster Kubernetes (AWS EKS) e o repositório de imagens Docker (AWS ECR).

---

## 🎯 Propósito do Repositório

Isolar e automatizar o provisionamento da infraestrutura de computação em nuvem necessária para suportar a aplicação principal e o banco de dados relacional. 

---

## 🛠️ Tecnologias Utilizadas

- **Terraform (`>= 1.5.0`)**: Infraestrutura como Código (IaC).
- **AWS EKS (Elastic Kubernetes Service)**: Cluster Kubernetes gerenciado.
- **AWS VPC & Networking**: Subnets públicas/privadas, Internet Gateway, NAT Gateway e Tabela de Roteamento.
- **AWS ECR (Elastic Container Registry)**: Registro privado de imagens de container (`ofisy-ecr`).
- **AWS IAM**: Gerenciamento de papéis de execução para cluster e worker nodes (compatível com AWS Academy / `LabRole`).
- **GitHub Actions**: Pipeline automatizada de CI/CD para deploy e destruição da infraestrutura.

---

## 📐 Arquitetura de Rede e EKS

```text
AWS Cloud (us-east-1)
 └── VPC (10.0.0.0/16)
      ├── Internet Gateway (IGW) & NAT Gateway (com Elastic IP)
      ├── Subnet Pública A (10.0.1.0/24 - us-east-1a) ── [ALB Load Balancer / Ingress]
      ├── Subnet Pública B (10.0.4.0/24 - us-east-1b) ── [ALB Load Balancer / Ingress]
      ├── Subnet Privada A (10.0.2.0/24 - us-east-1a) ── [EKS Worker Nodes / Pods]
      └── Subnet Privada B (10.0.3.0/24 - us-east-1b) ── [EKS Worker Nodes / Pods]
```

---

## 🔐 Configuração de Secrets no GitHub

Para a execução da pipeline de deploy (`Deploy EKS Infrastructure`), adicione as seguintes **Repository Secrets** no GitHub:

| Secret | Descrição |
| :--- | :--- |
| `AWS_ACCESS_KEY_ID` | Chave de acesso AWS |
| `AWS_SECRET_ACCESS_KEY` | Chave secreta AWS |
| `AWS_SESSION_TOKEN` | Token da sessão AWS (obrigatório para AWS Academy) |
| `AWS_ACCOUNT_ID` | ID da conta AWS |

---

## 🚀 Como Executar

### Opção A: Execução via GitHub Actions (Recomendado)

1. Vá até a aba **Actions** do repositório no GitHub.
2. Selecione a pipeline **`Deploy EKS Infrastructure (Terraform)`**.
3. Clique em **Run workflow** selecionando a branch desejada (ex: `main` ou `feature/185-eks-infra`).

---

### Opção B: Execução Local via CLI

#### 1. Pré-requisitos
- AWS CLI configurado (`aws configure`).
- Terraform `v1.5.0` ou superior instalado.

#### 2. Passos

```bash
# 1. Entre na pasta da infraestrutura
cd infra

# 2. Copie o arquivo de variáveis de exemplo
cp terraform.tfvars.example terraform.tfvars
cp backend.hcl.example backend.hcl

# 3. Preencha o account_id no terraform.tfvars e backend.hcl

# 4. Inicialize o Terraform
terraform init -backend-config=backend.hcl

# 5. Visualize o plano de execução
terraform plan

# 6. Aplique a infraestrutura
terraform apply -auto-approve
```

---

## 🔗 Repositórios Relacionados (Fase 3)

1. 🔐 **Serverless Function (Lambda)** — Autenticação de clientes via CPF e geração de JWT token.
2. ☁️ **[Infraestrutura EKS (Este repositório)](https://github.com/15SOAT-FIAP/techchallenge-ofisy-eks-infra)**
3. 🗄️ **[Infraestrutura RDS PostgreSQL](https://github.com/15SOAT-FIAP/techchallenge-ofisy-rds-infra)** — Provisionamento isolado do banco relacional gerenciado.
4. 🚀 **[Aplicação Principal em Kubernetes](https://github.com/15SOAT-FIAP/techchallenge-ofisy)** — Aplicação Spring Boot, Dockerfile, manifestos Kubernetes (`k8s/`) e CD.
