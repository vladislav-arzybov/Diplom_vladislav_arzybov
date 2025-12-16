### Деплой инфраструктуры в terraform pipeline

1. Если на первом этапе вы не воспользовались [Terraform Cloud](https://app.terraform.io/), то задеплойте и настройте в кластере [atlantis](https://www.runatlantis.io/) для отслеживания изменений инфраструктуры. Альтернативный вариант 3 задания: вместо Terraform Cloud или atlantis настройте на автоматический запуск и применение конфигурации terraform из вашего git-репозитория в выбранной вами CI-CD системе при любом комите в main ветку. Предоставьте скриншоты работы пайплайна из CI/CD системы.

#### Решение

> - Для настройки atlantis потребуются GITHUB_TOKEN, а также AWS_ACCESS_KEY_ID и AWS_SECRET_ACCESS_KEY т.к. в работе используется s3 backend
> - Получаем GITHUB_TOKEN в настройках профиля github: Profile → Settings → Developer settings → Personal access tokens
> - AWS_ACCESS_KEY_ID и AWS_SECRET_ACCESS_KEY получаем из ранее созданного файла для настройки s3 backend - secret.backend.tfvars (access_key и secret_key)
> - Для передачи секретов используется файл .env, содержащий переменные окружения (GITHUB_TOKEN, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY).
> - Файл подключается в shell-сессию командой ```source .env```, после чего его значения используются при создании secret в kubernetes.
> - Дополнительно файл .env добавлен в .gitignore и не хранится в репозитории, пример содержимого внутри .env:

```
export GITHUB_TOKEN=xxxxx
export AWS_ACCESS_KEY_ID=xxxxx
export AWS_SECRET_ACCESS_KEY=xxxxx
```

> Добавляем переменные окружения командой: 
- source .env

> Дополнительно можно проверить, что переменные сохранились корректно, выполнив команды:
- echo $GITHUB_TOKEN
- echo $AWS_ACCESS_KEY_ID
- echo $AWS_SECRET_ACCESS_KEY

> Создаем новый namespace - atlantis:
- kubectl create namespace atlantis

<img width="656" height="38" alt="изображение" src="https://github.com/user-attachments/assets/d33f6ec7-f207-4d2b-b790-998eb53f6541" />

> Создаем secrets вручную, командой: 

```
kubectl create secret generic atlantis-env \
  -n atlantis \
  --from-literal=AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
  --from-literal=AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
  --from-literal=GITHUB_TOKEN="$GITHUB_TOKEN"
```

<img width="784" height="109" alt="изображение" src="https://github.com/user-attachments/assets/6864d74b-3638-4788-992d-1393859ce37a" />

> Для автоматизации процесса деплоя необходимо также передать информацию о ```.authorized_key.json``` хранящимся локально, создаем секрет:

```
kubectl create secret generic atlantis-yc-sa \
  -n atlantis \
  --from-file=authorized_key.json=$HOME/.authorized_key.json
```

<img width="792" height="76" alt="изображение" src="https://github.com/user-attachments/assets/f312f2fa-fce9-463b-a227-a484d4d59824" />

> Ткже потребуется передать ssh public-key, чтобы не возникло ошибок при запуске Terraform внутри Atlantis

```
kubectl create secret generic ssh-public-key \
  -n atlantis \
  --from-file=ssh_public_key=$HOME/.ssh/id_rsa.pub
```

<img width="778" height="74" alt="изображение" src="https://github.com/user-attachments/assets/fb828519-0293-4dae-83b5-e1b6cde1c0d6" />

> Проверяем что всё ок командой:
- kubectl get secrets -n atlantis

<img width="632" height="94" alt="изображение" src="https://github.com/user-attachments/assets/b88f8187-2232-47ae-8e34-abe61a3359e4" />

> Подготавливаем yaml манифесты для деплоя atlantis

[atlantis-cm-terraform.yaml](https://github.com/vladislav-arzybov/HOMEWORK/blob/main/23_Diplom/05_atlantis/atlantis/01_atlantis-cm-terraform.yaml)
> Необходим для корректной работы atlantis с yandex cloud
```
apiVersion: v1
kind: ConfigMap
metadata:
  name: terraform-cli-config
  namespace: atlantis
data:
  terraform.rc: |
    provider_installation {
      network_mirror {
        url     = "https://terraform-mirror.yandexcloud.net/"
        include = ["registry.terraform.io/*/*"]
      }
      direct {
        exclude = ["registry.terraform.io/*/*"]
      }
    }
```

[atlantis-cm.yaml](https://github.com/vladislav-arzybov/HOMEWORK/blob/main/23_Diplom/05_atlantis/atlantis/01_atlantis-cm.yaml)
```
apiVersion: v1
kind: ConfigMap
metadata:
  name: atlantis-config
  namespace: atlantis
data:
  repos.yaml: |
    repos:
      - id: /.*/
        branch: /.*/
        allowed_overrides: [apply_requirements]
        apply_requirements: [approved]
        workflow: default

  atlantis.yaml: |
    workflows:
      default:
        plan:
          steps:
            - init
            - plan
        apply:
          steps:
            - apply
```

[atlantis-deployment.yaml](https://github.com/vladislav-arzybov/HOMEWORK/blob/main/23_Diplom/05_atlantis/atlantis/02_atlantis-deployment.yaml)
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: atlantis
  namespace: atlantis
spec:
  replicas: 1
  selector:
    matchLabels:
      app: atlantis
  template:
    metadata:
      labels:
        app: atlantis
    spec:
      containers:
        - name: atlantis
          image: ghcr.io/runatlantis/atlantis:v0.34.0
          imagePullPolicy: IfNotPresent

          args:
            - server
            - --port=4141
            - --config=/etc/atlantis/repos.yaml
            - --repo-config=/etc/atlantis/atlantis.yaml
            - --gh-user=vladislav-arzybov
            - --repo-allowlist=github.com/vladislav-arzybov/*
            - --gh-token=$(GITHUB_TOKEN)

          env:
            - name: TF_CLI_CONFIG_FILE
              value: /etc/terraform.d/terraform.rc

            - name: YC_SERVICE_ACCOUNT_KEY_FILE
              value: /home/atlantis/authorized_key.json

            - name: TF_VAR_ssh_public_key
              valueFrom:
                secretKeyRef:
                  name: ssh-public-key
                  key: ssh_public_key

          envFrom:
            - secretRef:
                name: atlantis-env

          ports:
            - name: http
              containerPort: 4141

          volumeMounts:
            - name: atlantis-config
              mountPath: /etc/atlantis/atlantis.yaml
              subPath: atlantis.yaml
              readOnly: true
            - name: atlantis-config
              mountPath: /etc/atlantis/repos.yaml
              subPath: repos.yaml
              readOnly: true

            - name: terraform-cli-config
              mountPath: /etc/terraform.d/terraform.rc
              subPath: terraform.rc
              readOnly: true

            - name: yc-sa-key
              mountPath: /home/atlantis/authorized_key.json
              subPath: authorized_key.json
              readOnly: true

      volumes:
        - name: atlantis-config
          configMap:
            name: atlantis-config

        - name: terraform-cli-config
          configMap:
            name: terraform-cli-config

        - name: yc-sa-key
          secret:
            secretName: atlantis-yc-sa
```

[atlantis-svc.yaml](https://github.com/vladislav-arzybov/HOMEWORK/blob/main/23_Diplom/05_atlantis/atlantis/03_atlantis-svc.yaml)
```
apiVersion: v1
kind: Service
metadata:
  name: atlantis
  namespace: atlantis
spec:
  type: NodePort
  selector:
    app: atlantis
  ports:
  - protocol: TCP
    port: 80
    targetPort: 4141
    nodePort: 30003
```

> Запускаем установку:
- kubectl apply -f 05_atlantis/atlantis/

<img width="786" height="92" alt="изображение" src="https://github.com/user-attachments/assets/0365c361-258d-4143-acc7-c71fdb2e1439" />

> Проверяем что всё работает
- kubectl get cm -n atlantis
- kubectl get all -n atlantis

<img width="773" height="309" alt="изображение" src="https://github.com/user-attachments/assets/0d4ba367-3a46-4740-a4a4-96ca4584f1bf" />

> Проверяем что сервис доступен из вне: http://158.160.0.253:30003/

<img width="1345" height="629" alt="изображение" src="https://github.com/user-attachments/assets/cedc8bf8-5284-48df-b8be-fa3c81c0f7ca" />

---

#### Настройка atlantis для работы с репозиторием

> Настраиваем Webhook, в настройках репозитория https://github.com/vladislav-arzybov/Diplom_vladislav_arzybov заходим в Настройки - Settings - Webhooks - Add webhook

<img width="806" height="110" alt="изображение" src="https://github.com/user-attachments/assets/7d00ca61-a21c-4cae-8fd6-ae99967c9824" />

- В ```Payload URL``` указываем ip мастера и порт atlantis'a http://158.160.0.253:30003/events
- В ```Content type``` - application/json
- В блоке ```Which events would you like to trigger this webhook?``` выбираем ```Let me select individual events.```, а затем выбираем:
> - Issue comments
> - Pull requests
> - Pull request reviews
> - Pushes

<img width="780" height="654" alt="изображение" src="https://github.com/user-attachments/assets/8428ce58-505f-4eb4-add8-5a9b78315387" />

> Нажимаем Add webhook

<img width="783" height="195" alt="изображение" src="https://github.com/user-attachments/assets/af08f8a6-e453-4849-a27b-e02c38688d1d" />

---

#### Проверяем работу atlantis, вносим изменения в текущую инфраструктуру

> Создаем новую ветку:
- git checkout -b test-atlantis

<img width="722" height="39" alt="изображение" src="https://github.com/user-attachments/assets/eb6cc1ca-0d1d-4b9f-9dd6-29fb8055495d" />

> Для теста добавляем network_load_balancer, чтобы обращения к приложению и графане могли осуществляться по 80 порту, по разным адресам.

[network_load_balancer.tf]()
```
# Создаем группу для балансировщика с включением всех нод
resource "yandex_lb_target_group" "k8s-nlb" {
  name       = "k8s-balancer-group"
  depends_on = [yandex_compute_instance.k8s]

  dynamic "target" {
    for_each = values(yandex_compute_instance.k8s)

    content {
      subnet_id = target.value.network_interface[0].subnet_id
      address   = target.value.network_interface[0].ip_address
    }
  }
}


# Настраиваем балансировщик для grafana
resource "yandex_lb_network_load_balancer" "grafana" {
  name = "grafana"

  listener {
    name        = "grafana-listener"
    port        = 80
    target_port = 30001
    external_address_spec {
      ip_version = "ipv4"
    }
  }
  attached_target_group {
    target_group_id = yandex_lb_target_group.k8s-nlb.id
    healthcheck {
      name = "healthcheck"
      tcp_options {
        port = 30001
      }
    }
  }

  depends_on = [yandex_lb_target_group.k8s-nlb]
}

# Настраиваем балансировщик для nginx
resource "yandex_lb_network_load_balancer" "nginx" {
  name = "nginx"
  listener {
    name        = "nginx-listener"
    port        = 80
    target_port = 30002
    external_address_spec {
      ip_version = "ipv4"
    }
  }
  attached_target_group {
    target_group_id = yandex_lb_target_group.k8s-nlb.id
    healthcheck {
      name = "healthcheck"
      tcp_options {
        port = 30002
      }
    }
  }
  depends_on = [yandex_lb_network_load_balancer.grafana]
}

```


> Пушим изменнеия в новую ветку:
- git add .
- git commit -m 'test-b'
- git push origin test-atlantis

<img width="897" height="342" alt="изображение" src="https://github.com/user-attachments/assets/30bfca49-8e61-4c4e-8410-ac6e39dc6137" />

> Проверяем что изменения передались в git, новая ветка с новым network_load_balancer.tf

<img width="917" height="501" alt="изображение" src="https://github.com/user-attachments/assets/cecb204b-f20e-40a2-88ef-bd703a1a16a8" />

> Переходим в Pull requests - нажимаем New pull request

<img width="1393" height="292" alt="изображение" src="https://github.com/user-attachments/assets/ddfbaf30-eb39-4235-8d63-1abf2d6d0ceb" />

> Выбираем процесс слияния из test-atlantis в main, нажимаем Create pull request

<img width="1243" height="235" alt="изображение" src="https://github.com/user-attachments/assets/0d17b200-ed12-4007-8cbc-2f6abc8f306d" />

> При необходимости можно указать заголовок и описание, затем нажать Create pull request

<img width="910" height="516" alt="изображение" src="https://github.com/user-attachments/assets/4624ab36-c74a-4134-94b4-dd567193468d" />

> После выполнения проверки откроется окно с инструкциями

<details>
  <summary>Plan</summary>

```
Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
+ create

Terraform will perform the following actions:

  # local_file.inventory_kubespray will be created
+ resource "local_file" "inventory_kubespray" {
      + content              = <<-EOT
            [all]
            master-node-1 ansible_host=84.201.132.33 ip=10.0.1.4
            worker-node-1 ansible_host=158.160.0.253 ip=10.0.2.27
            worker-node-2 ansible_host=158.160.219.173 ip=10.0.3.10
            
            [kube_control_plane]
            master-node-1
            
            [etcd]
            master-node-1
            
            [kube_node]
            worker-node-1
            worker-node-2
            
            [k8s_cluster:children]
            kube_control_plane
            kube_node
        EOT
      + content_base64sha256 = (known after apply)
      + content_base64sha512 = (known after apply)
      + content_md5          = (known after apply)
      + content_sha1         = (known after apply)
      + content_sha256       = (known after apply)
      + content_sha512       = (known after apply)
      + directory_permission = "0777"
      + file_permission      = "0777"
      + filename             = "ansible/inventory/inventory.ini"
      + id                   = (known after apply)
    }

  # yandex_lb_network_load_balancer.grafana will be created
+ resource "yandex_lb_network_load_balancer" "grafana" {
      + allow_zonal_shift   = (known after apply)
      + created_at          = (known after apply)
      + deletion_protection = (known after apply)
      + folder_id           = (known after apply)
      + id                  = (known after apply)
      + name                = "grafana"
      + region_id           = (known after apply)
      + type                = "external"

      + attached_target_group {
          + target_group_id = (known after apply)

          + healthcheck {
              + healthy_threshold   = 2
              + interval            = 2
              + name                = "healthcheck"
              + timeout             = 1
              + unhealthy_threshold = 2

              + tcp_options {
                  + port = 30001
                }
            }
        }

      + listener {
          + name        = "grafana-listener"
          + port        = 80
          + protocol    = (known after apply)
          + target_port = 30001

          + external_address_spec {
              + address    = (known after apply)
              + ip_version = "ipv4"
            }
        }
    }

  # yandex_lb_network_load_balancer.nginx will be created
+ resource "yandex_lb_network_load_balancer" "nginx" {
      + allow_zonal_shift   = (known after apply)
      + created_at          = (known after apply)
      + deletion_protection = (known after apply)
      + folder_id           = (known after apply)
      + id                  = (known after apply)
      + name                = "nginx"
      + region_id           = (known after apply)
      + type                = "external"

      + attached_target_group {
          + target_group_id = (known after apply)

          + healthcheck {
              + healthy_threshold   = 2
              + interval            = 2
              + name                = "healthcheck"
              + timeout             = 1
              + unhealthy_threshold = 2

              + tcp_options {
                  + port = 30002
                }
            }
        }

      + listener {
          + name        = "nginx-listener"
          + port        = 80
          + protocol    = (known after apply)
          + target_port = 30002

          + external_address_spec {
              + address    = (known after apply)
              + ip_version = "ipv4"
            }
        }
    }

  # yandex_lb_target_group.k8s-nlb will be created
+ resource "yandex_lb_target_group" "k8s-nlb" {
      + created_at      = (known after apply)
      + description     = (known after apply)
      + folder_id       = (known after apply)
      + id              = (known after apply)
      + labels          = (known after apply)
      + name            = "k8s-balancer-group"
      + region_id       = (known after apply)
      + target_group_id = (known after apply)

      + target {
          + address   = "10.0.1.4"
          + subnet_id = "e9bsoiol2c04lp3ddfnd"
        }
      + target {
          + address   = "10.0.2.27"
          + subnet_id = "e2lljuk1vt6rjao1p4vt"
        }
      + target {
          + address   = "10.0.3.10"
          + subnet_id = "fl837lr2ou8f54g1k60i"
        }
    }

Plan: 4 to add, 0 to change, 0 to destroy.
```

</details>

<img width="851" height="653" alt="изображение" src="https://github.com/user-attachments/assets/4c30bb05-ff9e-4c26-9ba9-559023c2dd66" />

> Чтобы выполнить terrafform apply необходимо в поле ```Add a comment``` указать ```atlantis apply -d 02_k8s/02_infra``` и нажать Comment

<img width="854" height="636" alt="изображение" src="https://github.com/user-attachments/assets/b5168ebb-6672-4674-b3b0-51216fead092" />

> Изменения внесены успешно

<details>
  <summary>Apply</summary>

```
local_file.inventory_kubespray: Creating...
yandex_lb_target_group.k8s-nlb: Creating...
local_file.inventory_kubespray: Creation complete after 0s [id=27d3f23e99db174f4bfccac282c65a898be437de]
yandex_lb_target_group.k8s-nlb: Creation complete after 2s [id=enpv1dchalo5nf6emo0i]
yandex_lb_network_load_balancer.grafana: Creating...
yandex_lb_network_load_balancer.grafana: Creation complete after 2s [id=enp1a5i8nj8s110kbsh3]
yandex_lb_network_load_balancer.nginx: Creating...
yandex_lb_network_load_balancer.nginx: Creation complete after 4s [id=enplsmnitb68orfoanl1]

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
```

</details>

<img width="874" height="612" alt="изображение" src="https://github.com/user-attachments/assets/d73d71e0-8235-4825-8399-7c2d6a0fdf5e" />

<img width="1251" height="610" alt="изображение" src="https://github.com/user-attachments/assets/49ea777f-0368-499e-bcc0-ab7f8067123b" />

> Проверяем наличие созданных балансировщиков:

<img width="1069" height="160" alt="изображение" src="https://github.com/user-attachments/assets/1803d701-7800-4f2b-a7ea-555b2d9de3bb" />

> Допполнительно для внесения изменений в main ветку и снятия блокировки в atlantis, необходимо нажать ```Merge pull request```

<img width="877" height="312" alt="изображение" src="https://github.com/user-attachments/assets/e9511a0c-6c4b-420c-8cd0-7676d3983676" />

<img width="910" height="427" alt="изображение" src="https://github.com/user-attachments/assets/191e8d8b-c76e-48d9-8bfb-54ebd7282772" />

<img width="1244" height="587" alt="изображение" src="https://github.com/user-attachments/assets/875bf4eb-e7d9-4958-b46a-761071e68525" />


---

#### Итого

Ожидаемый результат:
1. Git репозиторий с конфигурационными файлами для настройки Kubernetes.

> [Создание Kubernetes кластера](https://github.com/vladislav-arzybov/HOMEWORK/blob/main/23_Diplom/02_k8s/02_k8s.md)

2. Http доступ на 80 порту к web интерфейсу grafana.

> http://130.193.35.57:80
> Логин: admin
> Пароль: admin

3. Дашборды в grafana отображающие состояние Kubernetes кластера.
   
<img width="1801" height="957" alt="изображение" src="https://github.com/user-attachments/assets/9481e03b-7b12-464a-85ed-36b72a150307" />

4. Http доступ на 80 порту к тестовому приложению.

> http://158.160.201.83:80

<img width="682" height="174" alt="изображение" src="https://github.com/user-attachments/assets/df230efb-5081-4f1d-acf3-029535420764" />

5. Atlantis или terraform cloud или ci/cd-terraform

> http://84.201.132.33:30003/

<img width="1575" height="731" alt="изображение" src="https://github.com/user-attachments/assets/f9989086-288f-415e-9589-ce92d2a3dd5e" />

