### Установка и настройка CI/CD

Осталось настроить ci/cd систему для автоматической сборки docker image и деплоя приложения при изменении кода.

Цель:

1. Автоматическая сборка docker образа при коммите в репозиторий с тестовым приложением.
2. Автоматический деплой нового docker образа.

Можно использовать [teamcity](https://www.jetbrains.com/ru-ru/teamcity/), [jenkins](https://www.jenkins.io/), [GitLab CI](https://about.gitlab.com/stages-devops-lifecycle/continuous-integration/) или GitHub Actions.

Ожидаемый результат:

1. Интерфейс ci/cd сервиса доступен по http.

> Для выполнения данного блока воспользуюсь GitHub Actions, т.к. раньше не использовал его в работе как и Atlantis.

> Для начала создадим новый токен в DockerHub, в дальнейшем его значения будут использоваться в секрете DOCKERHUB_TOKEN:
- DockerHub - Account Settings - Personal access tokens - Generate new token

<img width="1600" height="254" alt="изображение" src="https://github.com/user-attachments/assets/f88d1795-c087-425f-8c62-5f763f115085" />

> Для выполнения второго задания, автоматического деплоя нового docker образа, необходимо заранее получить KUBE_CONFIG:
- cat ~/.kube/config | base64 -w0

> Полученную информацию необходимо добавить в репозиторий GitHub [my_nginx_test_app_diplom](https://github.com/vladislav-arzybov/my_nginx_test_app_diplom) в виде Secrets, это нужно для доступа к DockerHub и кластеру:
- Settings - Secrets and variables - Actions - New repository secret

```
DOCKERHUB_USERNAME
arzybov

DOCKERHUB_TOKEN
dckr_xxxxxxxx

KUBE_CONFIG
YXBpxxxxxxxxx
```

<img width="791" height="264" alt="изображение" src="https://github.com/user-attachments/assets/ccd8dc5f-bfda-4cac-bccd-12a19a615d2a" />

> Создадим необходиму структуру каталогов в ранее созданном репозитории [my_nginx_test_app_diplom](https://github.com/vladislav-arzybov/my_nginx_test_app_diplom)
- mkdir -p .github/workflows

---

2. При любом коммите в репозиторие с тестовым приложением происходит сборка и отправка в регистр Docker образа.

> Создадим workflow build-push.yaml:
- nano .github/workflows/build-push.yaml

[build-push.yaml](https://github.com/vladislav-arzybov/HOMEWORK/blob/main/23_Diplom/06_cicd/workflows/build-push.yaml)

```
name: Build and Push

on:
  push:
    branches:
      - "**"

jobs:
  docker-build:
    runs-on: ubuntu-22.04

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Login to DockerHub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: arzybov/test-app-nginx:1.0.${{ github.run_number }}
```

> Пушим в git
- git add .
- git commit -m 'build-push'
- git push origin main

<img width="796" height="271" alt="изображение" src="https://github.com/user-attachments/assets/54909fa3-a2d8-4701-a620-8f75b52132b0" />

<img width="1304" height="239" alt="изображение" src="https://github.com/user-attachments/assets/41f69923-f27f-4594-a701-42459dd9e4af" />

> Проверяем наличие образа в [DockerHub](https://hub.docker.com/repository/docker/arzybov/test-app-nginx/tags)

<img width="1575" height="310" alt="изображение" src="https://github.com/user-attachments/assets/a32b85d1-981a-4d2a-96fd-d6ebd781bf76" />

---

3. При создании тега (например, v1.0.0) происходит сборка и отправка с соответствующим label в регистри, а также деплой соответствующего Docker образа в кластер Kubernetes.

> Создадим workflow build-push-deploy.yaml:
- nano .github/workflows/build-push-deploy.yaml

[build-push-deploy.yaml](https://github.com/vladislav-arzybov/HOMEWORK/blob/main/23_Diplom/06_cicd/workflows/build-push-deploy.yaml)

```
name: build and deploy

on:
  push:
    tags:
      - "v*.*.*"

jobs:
  docker-deploy:
    runs-on: ubuntu-22.04

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Extract tag
        run: echo "IMAGE_TAG=${GITHUB_REF_NAME}" >> $GITHUB_ENV

      - name: Login to DockerHub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Build and push image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: arzybov/test-app-nginx:${{ env.IMAGE_TAG }}

      - name: Install kubectl
        uses: azure/setup-kubectl@v4
        with:
          version: v1.29.0

      - name: Configure kubeconfig
        run: |
          mkdir -p ~/.kube
          echo "${{ secrets.KUBE_CONFIG }}" | base64 -d > ~/.kube/config

      - name: Deploy to Kubernetes
        run: |
          kubectl -n app set image deployment/test-app-deployment \
            nginx-docker=arzybov/test-app-nginx:${{ env.IMAGE_TAG }}
```

> Заранее вносим правки в index.html, чтобы визуально увидеть изменения страницы.

```
<html>
<head>
DevOps-Netology-diplom
</head>
<body>
<h1>Hello! Welcome to my test app page. (v2.0.0)</h1>
</body>
</html>
```

> Пушим в git
- git add .
- git commit -m 'build-push-deploy-4'
- git push origin main

<img width="892" height="291" alt="изображение" src="https://github.com/user-attachments/assets/56275d2b-20f3-4b71-9bb7-10fb934cb471" />

> Добавляем тэг, v2.0.0, пушим в git
- git tag v2.0.0
- git push origin v2.0.0

<img width="690" height="92" alt="изображение" src="https://github.com/user-attachments/assets/ffce4e6c-01c0-46f6-af60-3b7df8ad86ce" />

> Проверяем сборку

<img width="1302" height="235" alt="изображение" src="https://github.com/user-attachments/assets/b8249935-9d71-4b4b-a9e8-a7b2ee78c46b" />

> Образ создан

<img width="1592" height="325" alt="изображение" src="https://github.com/user-attachments/assets/7062bf7d-779d-43d2-b571-86e00fc8e9f3" />

> История сборок

<img width="918" height="412" alt="изображение" src="https://github.com/user-attachments/assets/1cb487a3-0219-422f-b4a7-59b8e22c482b" />

> Деплой выполнен автоматически
- kubectl get all -n app -o wide

<img width="1554" height="253" alt="изображение" src="https://github.com/user-attachments/assets/6d5136c7-e09d-49f6-a535-a7d2ebaa393e" />

> Изменения на странице приложения актуальны

<img width="884" height="231" alt="изображение" src="https://github.com/user-attachments/assets/b0dca274-801d-4b60-83db-9068334a3394" />

