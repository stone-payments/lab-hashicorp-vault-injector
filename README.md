# Demo - Vault Sidecar Injector + Database Secret Engine

Na demonstração tecnica a seguir veremos a integração do Vault Sidecar Injector mais a utilização do Database secret engine no ecossistema do Kubernetes.
A ideia é apresentar um fluxo de trabalho onde o injector do Vault seja capaz de renderizar secrets das engines do Vault (Database Engine e Key Value Engine).

O Vault Sidecar Injector aproveita o webhook de [admissão de mutação do kubernetes]("https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/") para interceptar e argumentar (ou alterar) definições de pod especificamente anotadas para injeções de segredos.

Observação: Estamos assumindo que você esteja familizariado com operações no ecossistema do kubernetes e tenha o helm e terraform instalados também.

**IMPORTANTE**: As aplicações utilizadas aqui são exclusivamente para testes e estudos. Use por sua conta e risco e de preferência num abiente controlado não produtivo.

## Requerimentos para reprodução do ambiente:

Minimamente você precisará ter:

* Um Cluster Kubernetes em execução
* Uma instancia de banco de dados acessível (Aqui estamos usando postgres no RDS, mas pode ser qualquer Banco de dados suportado pelo Vault). [Aqui](https://bitnami.com/stack/postgresql/helm) você encontra um exemplo para deploy do postgres dentro do ambiente K8S caso nao queira subir uma instância RDS.
* Uma aplicação que se conecte ao banco de dados acima. Esse repositório contém uma [aplicação](./postgrees-app/) de exemplo para se conectar à um banco Postgres.

## Referências
* https://learn.hashicorp.com/tutorials/vault/database-secrets
* https://learn.hashicorp.com/tutorials/vault/kubernetes-sidecar
* https://github.com/jweissig/vault-k8s-sidecar-demo
* https://www.vaultproject.io/docs/platform/k8s/injector/annotations
* https://docs.aws.amazon.com/emr/latest/EMR-on-EKS-DevelopmentGuide/setting-up-enable-IAM.html

###  Clonar repositório
```bash
git clone https://github.com/stone-payments/lab-hashicorp-vault-injector.git
cd lab-hashicorp-vault-injector
```
### Deploy do Vault
Estamos assumindo que você já tenha um cluster Kubernetes em funcionamento. Sendo assim, para fazer o deploy do Vault, bem como a sua configuração faça:
```bash
cd setup && terraform init && terraform apply
```

O código terraform faz:

* Deploy e unseal do Vault
* Habilita a engine Database
* Habilita e configura os backends de autenticação: Kubernetes, AppRole e AWS.
* Configura as policies
* Configura as roles dos backends de autenticação
* Habilita e Configura conexão com a base de dados
* Configura as roles de criação

### Deploy das aplicações

**Para fins didáticos** vamos primeiro realizar o deploy da nossa aplicação **da maneira mais insegura possível**: Hardcode. ``` k apply -f k8s-manifests/vida-loka-hashi-app.yaml```

**ATENÇÃO: não usar esse modelo em produção em hipótese alguma!**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vida-loka-hashi-app
  namespace: vault-hashitalks
  labels:
    app: hashi-app
spec:
  selector:
    matchLabels:
      app: hashi-app
  replicas: 1
  template:
    metadata:
      labels:
        app: hashi-app
    spec:
      serviceAccountName: vault-hashitalks
      containers:
        - name: evil-hashiapp
          image: docker.io/igoritosousa22/postgrees-live:2022-07-22
          command: ['/bin/bash']
          args: ['-c', '/app/postgrees-live']
          envFrom:
            - configMapRef:
                name: hashi-data
---
apiVersion: v1
data:
  DATABASE_PASSWORD: "StrongPassword@2022"
  DATABASE_USER: "administrador-manual"
  DATABASE_NAME: "app_db"
  DATABASE_HOST: "mydatabase.local:5432"
kind: ConfigMap
metadata:
  name: hashi-data
  namespace: vault-hashitalks
```

Esse modelo é extremamente inseguro, pois as credenciais estão expostas. Qualquer pessoal com acesso a esse manifesto pode comprometer a aplicação.

### Injetando credenciais de forma segura

#### App Role
O modelo abaixo utiliza o backend de autenticação do Vault App Role. Esse modelo adiciona uma camada de segurança porém ainda é necessário criar um objeto de secret no K8S com os dados da role-id e secret-id. Essa etapa adiciona essa ação manual de criação da secret e pode ser que no longo prazo não seja tão eficiente.

![imagem](https://user-images.githubusercontent.com/73206099/181245863-5c28b804-4076-4c8d-ae99-c42b400bdee5.png)

 ``` k apply -f k8s-manifests/app-role-auth-hashiapp.yaml```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-approle-auth-hashiapp
  namespace: vault-hashitalks
  labels:
    app: app-approle
spec:
  selector:
    matchLabels:
      app: app-approle
  replicas: 1
  template:
    metadata:
      annotations:
        vault.hashicorp.com/agent-inject: 'true'
        vault.hashicorp.com/role: 'vault-hashitalks-approle'
        vault.hashicorp.com/agent-extra-secret: 'approle'
        vault.hashicorp.com/auth-type: 'approle'
        vault.hashicorp.com/auth-path: 'auth/approle'
        vault.hashicorp.com/auth-config-role-id-file-path: '/vault/custom/role-id'
        vault.hashicorp.com/auth-config-secret-id-file-path: '/vault/custom/secret-id'
        vault.hashicorp.com/agent-inject-secret-db-creds: 'database/rds/postgres/vault-hashi-talks-mock/creds/readonly'
        vault.hashicorp.com/agent-inject-template-db-creds: |
          {{ with secret "database/rds/postgres/vault-hashi-talks-mock/creds/readwrite" -}}
            export DATABASE_USER="{{ .Data.username }}"
          {{- end }}
          {{ with secret "database/rds/postgres/vault-hashi-talks-mock/creds/readwrite" -}}
            export DATABASE_PASSWORD="{{ .Data.password }}"
          {{- end }}
      labels:
        app: app-approle
    spec:
      serviceAccountName: vault-hashitalks
      containers:
        - name: hashiapp
          image: docker.io/igoritosousa22/postgrees-live:2022-07-22
          command: ['/bin/bash']
          args: ['-c', '. /vault/secrets/db-creds && /app/postgrees-live']
          envFrom:
            - configMapRef:
                name: hashi-data
---
apiVersion: v1
data:
  DATABASE_NAME: "app_db"
  DATABASE_HOST: "mydatabase.local:5432"
kind: ConfigMap
metadata:
  name: hashi-data
  namespace: vault-hashitalks
```

#### Kubernetes Auth
O modelo abaixo utiliza o backend de autenticação do Vault Kubernetes. Esse modelo já é mais eficiente que o anterior, pois não há qualquer ação manual além de instrumentar o manifesto k8s da aplicação. Será necessário atachar ao PoD uma service account que fará o bound nas configurações de Role do Vault.  Além disso o manifesto K8S da aplicação precisará ter annotations específicas e também alguma instrução de onde e como renderizar as secrets. 

![imagem](https://user-images.githubusercontent.com/73206099/181245986-fc931e8b-a41f-4c97-99e9-60cd700ba57d.png)


 ``` k apply -f k8s-manifests/k8s-auth-hashiapp.yaml```


```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: k8s-auth-hashi-app
  namespace: vault-hashitalks
  labels:
    app: hashi-app
spec:
  selector:
    matchLabels:
      app: hashi-app
  replicas: 1
  template:
    metadata:
      annotations:
        vault.hashicorp.com/agent-inject: 'true' # annotation que diz ao injector para realizar a mutação no pod
        vault.hashicorp.com/agent-inject-secret-database-config: 'database/rds/postgres/vault-hashi-talks-mock/creds/readonly' # path da secret engined database
        vault.hashicorp.com/agent-inject-template-database-config: | 
          {{ with secret "database/rds/postgres/vault-hashi-talks-mock/creds/readonly" -}}
            export DATABASE_USER="{{ .Data.username }}"
          {{- end }}
          {{ with secret "database/rds/postgres/vault-hashi-talks-mock/creds/readonly" -}}
            export DATABASE_PASSWORD="{{ .Data.password }}"
          {{- end }}
        vault.hashicorp.com/role: 'vault-hashitalks-role' # role que possui a policy de acesso
      labels:
        app: hashi-app
    spec:
      serviceAccountName: vault-hashitalks
      containers:
        - name: hashiapp
          image: docker.io/igoritosousa22/postgrees-live:2022-07-22
          command: ['/bin/bash']
          args: ['-c', '. /vault/secrets/database-config && /app/postgrees-live'] #Indica para aplicação qual o diretório e como renderizar as credenciais
          envFrom:
            - configMapRef:
                name: hashi-data
---
apiVersion: v1
data:
  DATABASE_NAME: "app_db"
  DATABASE_HOST: "mydatabase.local:5432"
kind: ConfigMap
metadata:
  name: hashi-data
  namespace: vault-hashitalks
```

#### Aws Auth
O modelo abaixo utiliza o backend de autenticação do Vault AWS auth. Esse modelo é tão eficiente quanto o anterior (Kubernetes auth). Uma das vantagens é a possibilidade de utilizar o IAM da aws em conjunto com o vault no processo de autenticação. Com esse método além de autenticar no Vault, a aplicação pode usar a mesma service accoount para se autenticar e acessar recursos no ecossistema da AWS via IAM Role Service Account (IRSA). Lembrando que esse modelo de autenticação é específico para AWS e só irá funcionar para escopos que se utilizem do serviço de compute da AWS (EC2) como o EKS. 

![imagem](https://user-images.githubusercontent.com/73206099/181246091-eceb0a9c-e152-4edc-ac4a-30d96250f2f0.png)


 ``` k apply -f k8s-manifests/aws-auth-hashiapp.yaml```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aws-auth-hashi-app
  namespace: app-example-iam-auth
  labels:
    app: hashi-app
spec:
  selector:
    matchLabels:
      app: hashi-app
  replicas: 1
  template:
    metadata:
      annotations:
        vault.hashicorp.com/agent-inject: 'true' # annotation que diz ao injector para realizar a mutação no pod
        vault.hashicorp.com/agent-configmap: 'aws-auth-config'
      labels:
        app: hashi-app
    spec:
      serviceAccountName: app-example-iam-auth
      containers:
        - name: hashiapp
          image: docker.io/igoritosousa22/postgrees-live:2022-07-22
          command: ['/bin/bash']
          args: ['-c', '. /vault/secrets/database-config && /app/postgrees-live']
          envFrom:
            - configMapRef:
                name: hashi-data
---
apiVersion: v1
data:
  DATABASE_NAME: "app_db"
  DATABASE_HOST: "mydatabase.local:5432"
kind: ConfigMap
metadata:
  name: hashi-data
  namespace: app-example-iam-auth
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth-config
  namespace: app-example-iam-auth
data:
  config.hcl: |
    "auto_auth" = {
      "method" "aws" {
        "mount_path" = "auth/aws"
        "config" = {
          "role" = "app-example-iam-auth"
          "type" = "iam"
        }
      }

      "sink" = {
        "config" = {
          "path" = "/home/vault/.vault-token"
        }

        "type" = "file"
      }
    }

    "exit_after_auth" = false
    "pid_file" = "/home/vault/.pid"

    "template" = {
      "contents" = "{{ with secret \"database/rds/postgres/vault-hashi-talks-mock/creds/readonly\" -}}\n  export DATABASE_USER=\"{{ .Data.username }}\"\n{{- end }}\n{{ with secret \"database/rds/postgres/vault-hashi-talks-mock/creds/readonly\" -}}\n  export DATABASE_PASSWORD=\"{{ .Data.password }}\"\n{{- end }}"
      "destination" = "/vault/secrets/database-config"
    }

    "vault" = {
      "address" = "http://vault.vault-hashitalks.svc:8200"
    }
  config-init.hcl: |
    "auto_auth" = {
      "method" "aws" {
        "mount_path" = "auth/aws"
        "config" = {
          "role" = "app-example-iam-auth"
          "type" = "iam"
        }
      }

      "sink" = {
        "config" = {
          "path" = "/home/vault/.vault-token"
        }

        "type" = "file"
      }
    }

    "template" = {
      "contents" = "{{ with secret \"database/rds/postgres/vault-hashi-talks-mock/creds/readonly\" -}}\n  export DATABASE_USER=\"{{ .Data.username }}\"\n{{- end }}\n{{ with secret \"database/rds/postgres/vault-hashi-talks-mock/creds/readonly\" -}}\n  export DATABASE_PASSWORD=\"{{ .Data.password }}\"\n{{- end }}"
      "destination" = "/vault/secrets/database-config"
    }  

    "exit_after_auth" = true
    "pid_file" = "/home/vault/.pid"

    "vault" = {
      "address" = "http://vault.vault-hashitalks.svc:8200"

    }
```

Cada um dos modelos de autenticação apresentados acima, irá montar as credenciais da Database Engine num volume compartilhado entre container da Aplicação e Vault-Agent.

**IMPORTANTE**: Cada aplicação irá receber as credeniais de uma maneira específica. A aplicação desse repositório renderiza as credenciais como variáveis de ambiente, no entanto isso não é uma unanimidade. 

