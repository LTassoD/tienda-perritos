# Guión de Defensa Técnica — Evaluación 3

## 1. Arquitectura del Proyecto (~2 min)

"Muy buenos días, soy Luis Tasso y voy a presentar el proyecto tienda-perritos, una aplicación web de tres capas dockerizada desplegada en AWS ECS Fargate con CI/CD automatizado."

"La aplicación gestiona productos de una tienda de alimentos para perros. Consta de:
- Frontend: Nginx sirviendo HTML + JavaScript vanilla
- Backend: API REST Node.js + Express
- Base de datos: MySQL 8"

(Mostrar en GitHub: estructura del repo, docker-compose.yml, frontend/Dockerfile, backend/Dockerfile, db/Dockerfile)

## 2. Docker Compose local (~3 min)

"Abrimos terminal y con un solo comando levantamos los 3 servicios:"
```
docker compose up -d
```
(Mostrar `docker ps` con 3 contenedores)

"Abrimos http://localhost — ahí está el frontend."

"Probamos la API: http://localhost/api/productos — devuelve 3 productos en JSON."

"Hacemos CRUD completo:"
1. Crear: llenar formulario, guardar
2. Editar: cambiar precio/stock
3. Eliminar: confirmar eliminación

"El truco del nginx: usa `resolver 127.0.0.11` (DNS de Docker) con `proxy_pass http://backend:3001` para conectar al backend."

"Paramos con: `docker compose down`"

## 3. Pipeline CI/CD (~3 min)

(Mostrar `.github/workflows/deploy.yml` en GitHub)

"El pipeline se activa con cada push a main. Pasos:"
1. Checkout del código
2. Configurar credenciales AWS (Access Key, Secret Key, Session Token como Secrets)
3. Login a Amazon ECR
4. Build & Push de 3 imágenes (frontend, backend, db)
5. Registrar task definitions en ECS
6. Force new deployment en los servicios

"Detalle importante: para ECS uso `default.conf.ecs` (sin proxy_pass, solo archivos estáticos) copiándolo sobre `default.conf` antes del build. Así el frontend en ECS no intenta conectar a 'backend' (que no existe), porque el ALB maneja las rutas /api/*."

(Mostrar workflow #7 en Actions — verde, pass en 9s)

## 4. Infraestructura AWS (~4 min)

"En AWS usé ECS Fargate por ser serverless — no pago por nodos EC2."

(Entrar a Consola AWS → ECS → tienda-perritos-cluster)

"Tengo 2 servicios:"
- **frontend-service**: 1 tarea corriendo (Nginx, solo estáticos)
- **backend-service**: 1 tarea corriendo (Node.js + MySQL sidecar, comparten localhost)

(Click en frontend-service → tarea → detalles)

"Cada tarea Fargate con 256 CPU y 512 MB RAM."

(Volver → EC2 → Target Groups)

"Application Load Balancer 'tienda-perritos-alb' con 2 target groups:"
- **tg-frontend**: health check a / → healthy
- **tg-backend**: health check a /api/productos → healthy

(Ver Listener en ALB)

"El listener del ALB enruta:"
- /api/* → tg-backend
- / → tg-frontend

(VPC → Security Groups)

"Security Groups - mínimo privilegio:"
- `tienda-alb-sg`: puerto 80 desde 0.0.0.0/0
- `tienda-frontend-sg`: puerto 80 solo desde ALB
- `tienda-backend-sg`: puerto 3001 solo desde ALB

(Mostrar ALB funcionando:)

"Frontend: http://tienda-perritos-alb-586299045.us-east-1.elb.amazonaws.com — 200 OK"
"API: /api/productos — 3 productos en JSON"

## 5. Mejoras y reflexión (~1 min)

"Oportunidades de mejora:
- Multi-stage builds para reducir tamaño de imágenes (nginx alpine ya es pequeño)
- Docker layer caching para builds más rápidos
- Tests automatizados antes del deploy
- Rollback automático si falla health check
- Migrar a Terraform/CDK en vez de scripts manuales"

"Este proyecto demuestra integración continua, despliegue automatizado y orquestación serverless en AWS con GitHub Actions + ECS Fargate"

## Tiempo total estimado: 13-15 min
