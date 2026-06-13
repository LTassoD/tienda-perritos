# Guía rápida: Despliegue del proyecto tienda-perritos

## Requisitos
- Docker Desktop
- Cuenta AWS con créditos
- Cuenta GitHub

## 1. Ejecutar local (Docker Compose)
```bash
docker compose up -d
# Frontend: http://localhost
# Backend:  http://localhost:3001/api/productos
```

## 2. Subir a GitHub
```bash
# Crear repo en GitHub y luego:
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/TU_USUARIO/tienda-perritos.git
git push -u origin main
```

## 3. Configurar AWS
```bash
# Crear ECR repositorios
aws ecr create-repository --repository-name tienda-perritos-frontend
aws ecr create-repository --repository-name tienda-perritos-backend
aws ecr create-repository --repository-name tienda-perritos-db

# Crear clúster ECS
aws ecs create-cluster --cluster-name tienda-perritos-cluster

# Ver infraestructura completa en infrastructure/
```

## 4. Configurar GitHub Secrets
Ir a Settings → Secrets and variables → Actions:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

## 5. Push a main → Pipeline se ejecuta automáticamente
