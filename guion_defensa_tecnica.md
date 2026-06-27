# Guión de Defensa Técnica — Evaluación 3

## 1. Arquitectura del Proyecto (~2 min)

"Buenos días, soy Luis Tasso y voy a presentar el proyecto tienda-perritos, una aplicación web de tres capas dockerizada desplegada en AWS ECS Fargate con CI/CD automatizado."

"La aplicación gestiona productos de una tienda de alimentos para perros. Consta de:
- Frontend: Nginx sirviendo HTML + JavaScript vanilla
- Backend: API REST Node.js + Express
- Base de datos: MySQL 8"

## 2. Docker Compose local (~3 min)

"Localmente uso Docker Compose. Con un solo comando levanto los 3 contenedores."
(Mostrar terminal y navegador)

"Puedo hacer CRUD completo desde el frontend."
(Crear, editar y eliminar un producto)

## 3. Infraestructura AWS (~3 min)

"En AWS usé ECS Fargate por ser serverless y no pagar por nodos."

"Tengo dos task definitions:
- Frontend: Nginx en Fargate
- Backend + DB: Node.js y MySQL en sidecar (comparten localhost)"

"Un Application Load Balancer recibe el tráfico HTTP y lo enruta:
- /api/* → Backend
- / → Frontend"

"Los Security Groups siguen el principio de mínimo privilegio:
- ALB SG: puerto 80 desde internet
- Frontend SG: puerto 80 solo desde ALB
- Backend SG: puerto 3001 solo desde ALB"

## 4. Pipeline CI/CD (~3 min)

"El pipeline con GitHub Actions se activa con cada push a main:"
(Mostrar workflow y ejecución verde)

"Pasos: Checkout → Configurar AWS → Login ECR → Build & Push 3 imágenes → Deploy a ECS"

"Las credenciales están protegidas como Secrets en GitHub."

## 5. Mejoras y reflexión (~2 min)

"Oportunidades de mejora:
- Multi-stage builds para reducir tamaño de imágenes
- Docker layer caching para builds más rápidos
- Tests automatizados antes del deploy
- Rollback automático si falla health check"

"Este proyecto demuestra integración continua, despliegue automatizado y orquestación serverless en AWS."

## Tiempo total estimado: 13-15 min
