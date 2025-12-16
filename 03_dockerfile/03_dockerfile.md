### Создание тестового приложения

Для перехода к следующему этапу необходимо подготовить тестовое приложение, эмулирующее основное приложение разрабатываемое вашей компанией.

Способ подготовки:

1. Рекомендуемый вариант:  
   а. Создайте отдельный git репозиторий с простым nginx конфигом, который будет отдавать статические данные.  
   б. Подготовьте Dockerfile для создания образа приложения.  
2. Альтернативный вариант:  
   а. Используйте любой другой код, главное, чтобы был самостоятельно создан Dockerfile.

### РЕШЕНИЕ

> Создаем новый репозиторий ```my_nginx_test_app_diplom``` на https://github.com

<img width="762" height="122" alt="изображение" src="https://github.com/user-attachments/assets/7a01a71a-44d7-4808-8f92-adaf67f1163c" />

> Копируем созданный репозиторий в локальный каталог: ```git clone git@github.com:vladislav-arzybov/my_nginx_test_app_diplom.git```

<img width="1023" height="112" alt="изображение" src="https://github.com/user-attachments/assets/40c22f87-3276-4ef8-848d-43bacca10508" />

> Подготовим index.html страницу для nginx:

```
<html>
<head>
DevOps-Netology-diplom
</head>
<body>
<h1>Hello! Welcome to my test app page.</h1>
</body>
</html>
```

> Создаем Dockerfile

```
# Последний стабильный образ с nginx
FROM nginx:1.27.2

# Копируем ранее созданный шаблон index.html заменяя стандартную страницу nginx
COPY index.html /usr/share/nginx/html

# Порт который будет слушать контейнер
EXPOSE 80
```

> Собираем образ: ```docker build -t arzybov/test-app-nginx:1.0.0 .```

<img width="1006" height="468" alt="изображение" src="https://github.com/user-attachments/assets/092142c7-8360-4c6b-a9a7-2e04944b5f45" />

> Проверяем создание образа ```docker images```

<img width="1082" height="56" alt="изображение" src="https://github.com/user-attachments/assets/10eae2ab-344e-43b8-96cc-9a17722541f8" />

> Проверяем работоспособность контейнера: ```docker run -d -p 8080:80 arzybov/test-app-nginx:1.0.0```

<img width="1461" height="93" alt="изображение" src="https://github.com/user-attachments/assets/d3f5e72a-4309-4bac-a05b-ba18352647c8" />

> Выполняем curl на порт 8080, видим что nginx работает корректно и ранее созданная страница доступна.

<img width="768" height="165" alt="изображение" src="https://github.com/user-attachments/assets/3d025f6d-ae34-4882-89cd-64dee7d49d14" />
   
---

Ожидаемый результат:

1. Git репозиторий с тестовым приложением и Dockerfile.

> Добавляем ранее созданные index.html и Dockerfile в репозиторий: https://github.com/vladislav-arzybov/my_nginx_test_app_diplom
- git add .
- git commit -m 'app01'
- git push origin main

<img width="805" height="272" alt="изображение" src="https://github.com/user-attachments/assets/12653f68-f875-4f4d-8969-ad5148ade074" />

> Проверяем изменения, все файлы успешно отправлены в удаленный репозиторий на github.com

<img width="906" height="311" alt="изображение" src="https://github.com/user-attachments/assets/3147b9ad-dc49-44df-bc79-125a281172b9" />

---

2. Регистри с собранным docker image. В качестве регистри может быть DockerHub или [Yandex Container Registry](https://cloud.yandex.ru/services/container-registry), созданный также с помощью terraform.

> В качестве регистри выбрал DockerHub т.к. ранее уже создавал и пушил в него образы. Подключаемся к регистри через ```docker login``` и выполняем команду: ```docker push arzybov/test-app-nginx:1.0.0```

<img width="981" height="199" alt="изображение" src="https://github.com/user-attachments/assets/519023d8-2bcd-4408-840f-e2258305ccaa" />

> Проверяем образ на портале: https://hub.docker.com/repository/docker/arzybov/test-app-nginx/general

<img width="934" height="507" alt="изображение" src="https://github.com/user-attachments/assets/3d85a3ad-bf7f-48e7-b7b0-e6e2f580c950" />

> Дополнительно можно ещё раз проверить загрузку и запуск образа, предварительно остановив и удалив ранее запущенный тестовый контейнер и созданный образ.

- docker pull arzybov/test-app-nginx:1.0.0

<img width="1104" height="287" alt="изображение" src="https://github.com/user-attachments/assets/fa8bb214-90fd-479f-abc8-df7bb903dbb5" />

- docker run -d -p 8080:80 arzybov/test-app-nginx:1.0.0
- docker ps
- curl localhost:8080

<img width="1476" height="256" alt="изображение" src="https://github.com/user-attachments/assets/755e84ce-83e5-4e62-bb78-a05f7013e690" />


