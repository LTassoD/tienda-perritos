# Guión de Defensa Técnica — Evaluación 3
## Despliegue de tienda-perritos con Docker + ECS + CI/CD
### Duración objetivo: 13-15 min

---

## SEGMENTO 1: Arquitectura del proyecto (2 min)

**Narración:**
"Muy buenos días, soy Luis Tasso y voy a presentar el proyecto tienda-perritos, una aplicación web de tres capas dockerizada desplegada en AWS ECS Fargate con CI/CD automatizado."

**Acción:** Mostrar GitHub repo → estructura del proyecto

"Este repo contiene la aplicación completa. Tenemos 3 carpetas principales:"

**Acción:** Click en `frontend/`
"- Frontend: carpeta frontend con un Dockerfile que usa nginx:alpine, su configuración default.conf, el index.html y app.js"

**Acción:** Click en `backend/`
"- Backend: Node.js + Express con server.js, expone el puerto 3001"

**Acción:** Click en `db/`
"- Base de datos: MySQL 8 con un init.sql que crea la tabla productos y la seed de datos"

**Acción:** Click en `docker-compose.yml`
"Y el docker-compose.yml que orquesta los 3 servicios. Define una red interna 'tienda-net' y mapea puertos: frontend en 80, backend en 3001, db en 3307."

---

## SEGMENTO 2: Docker Compose local (3 min)

**Acción:** Abrir terminal (Git Bash)

**Narración:**
"Con un solo comando levantamos los 3 contenedores:"

**Acción:** Escribir y ejecutar:
```bash
docker compose up -d
```

**Narración:**
"Y con docker ps vemos los 3 contenedores activos:"

**Acción:** Ejecutar:
```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

**Narración:**
"Tenemos tienda-frontend en puerto 80, tienda-backend en 3001, tienda-db en 3307."

**Acción:** Abrir navegador en http://localhost

**Narración:**
"La interfaz carga — es una SPA simple con un formulario y la tabla de productos."

**Acción:** Abrir http://localhost/api/productos en otra pestaña

**Narración:**
"La API devuelve los 3 productos en JSON. Hagamos CRUD:"

**Acción:** Llenar formulario (nombre: "Hueso Carnoso", precio: 3500, stock: 20) → click "Agregar"

**Narración:**
"Creé un nuevo producto. Aparece en la tabla."

**Acción:** Click "Editar" en el producto nuevo → cambiar stock a 25 → guardar

**Narración:**
"Edité el stock. La tabla se actualiza."

**Acción:** Click "Eliminar" → confirmar

**Narración:**
"Eliminé el producto. CRUD completo funcionando."

**Acción:** Volver a terminal → ejecutar:
```bash
docker compose down
```

**Narración:**
"Con docker compose down detenemos todo."

---

## SEGMENTO 3: Pipeline CI/CD (3 min)

**Acción:** Volver a GitHub → pestaña Actions

**Narración:**
"GitHub Actions automatiza el despliegue. Cada push a main dispara el workflow."

**Acción:** Click en `.github/workflows/deploy.yml`

**Narración:**
"El workflow tiene 3 fases:"

**Acción:** Señalar paso "Checkout repo"
"1. Checkout del código"

**Acción:** Señalar paso "Configure AWS credentials"
"2. Configura credenciales AWS desde GitHub Secrets — Access Key, Secret Key y Session Token"

**Acción:** Señalar paso "Login to Amazon ECR"
"3. Login a ECR — los repositorios de imágenes"

**Acción:** Señalar "Build & push frontend"
"4. Build y push de las 3 imágenes: frontend, backend, db. Notar el truco: cp frontend/default.conf.ecs frontend/default.conf — para ECS usamos una config sin proxy_pass, porque el ALB maneja /api/*."

**Acción:** Señalar "Register task definition"
"5. Registra las task definitions actualizadas"

**Acción:** Señalar "Update ECS services"
"6. Fuerza nuevo deployment en ECS con --force-new-deployment"

**Acción:** Volver a Actions → workflow #7

**Narración:**
"Este es el último run. Pasó en 9 segundos — los builds usan cache de Docker."

---

## SEGMENTO 4: Infraestructura AWS (4 min)

**Acción:** Abrir Consola AWS → buscar "ECS"

**Narración:**
"Entramos a ECS. Elegí Fargate por ser serverless — no pago por nodos EC2, solo por los recursos que uso."

**Acción:** Click en Clusters → `tienda-perritos-cluster`

**Narración:**
"El cluster tiene 2 servicios: frontend-service y backend-service, cada uno con 1 tarea."

**Acción:** Click en `frontend-service` → luego en la tarea (el link azul)

**Narración:**
"Cada tarea Fargate usa 256 CPU y 512 MB RAM. El frontend solo sirve archivos estáticos."

**Acción:** Click en pestaña "Configuration" → mostrar detalles del task definition

**Narración:**
"La imagen viene de ECR. Puerto 80 mapeado a 80. Sin health check adicional — el ALB lo verifica."

**Acción:** Volver a Consola → buscar "EC2" → "Target Groups"

**Narración:**
"El ALB distribuye tráfico. Dos target groups:"

**Acción:** Click en `tg-frontend` → pestaña "Targets"

**Narración:**
"tg-frontend: health check a GET / espera 200. La IP interna 172.31.x.x está healthy."

**Acción:** Click en `tg-backend` → pestaña "Targets"

**Narración:**
"tg-backend: health check a GET /api/productos. También healthy."

**Acción:** Volver a EC2 → "Load Balancers" → click en `tienda-perritos-alb` → pestaña "Listeners"

**Narración:**
"El listener del ALB: regla por defecto (/) → tg-frontend. Regla condicional: si path es /api/* → tg-backend."

**Acción:** Navegar a VPC → "Security Groups"

**Narración:**
"Security Groups con mínimo privilegio:"

**Acción:** Click en `tienda-alb-sg`

**Narración:**
"ALB: puerto 80 abierto a internet (0.0.0.0/0)."

**Acción:** Click en `tienda-frontend-sg`

**Narración:**
"Frontend: puerto 80 solo desde el SG del ALB."

**Acción:** Click en `tienda-backend-sg`

**Narración:**
"Backend: puerto 3001 solo desde el SG del ALB."

**Acción:** Abrir en navegador: http://tienda-perritos-alb-586299045.us-east-1.elb.amazonaws.com

**Narración:**
"El frontend desde ALB responde 200."

**Acción:** Abrir /api/productos

**Narración:**
"La API devuelve los productos. Todo funcionando."

---

## SEGMENTO 5: Mejoras y reflexión (1 min)

**Narración:**
"El pipeline funciona pero se puede mejorar:"

"1. Multi-stage builds para reducir aún más las imágenes"
"2. Paralelizar builds de frontend y backend en el pipeline"
"3. Agregar tests automatizados antes del deploy"
"4. Rollback automático si el health check del ALB falla"
"5. Migrar a Infraestructura como Código con Terraform/CDK"

"Este proyecto demuestra el ciclo DevOps completo: desarrollo local con Docker Compose, automatización con GitHub Actions, y orquestación serverless con ECS Fargate en AWS."

"Muchas gracias por su atención."

---

## Tiempo total: 13-15 min
