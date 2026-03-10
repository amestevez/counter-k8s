#!/bin/bash
set -e

echo "🚀 Iniciando counter-app en Kubernetes..."

# ─── 1. Registry ───────────────────────────────────────────────
echo ""
echo "📦 [1/6] Levantando registry local..."
if docker ps -a --format '{{.Names}}' | grep -q "^registry$"; then
  docker start registry 2>/dev/null || true
  echo "   Registry ya existía, arrancado."
else
  docker run -d --name registry --restart=always -p 5000:5000 registry:2
  echo "   Registry creado."
fi

# ─── 2. Clúster kind ───────────────────────────────────────────
echo ""
echo "☸️  [2/6] Creando clúster kind..."
if kind get clusters 2>/dev/null | grep -q "^kind$"; then
  echo "   El clúster 'kind' ya existe, omitiendo creación."
else
  kind create cluster --config kind-config.yaml
fi

# ─── 3. Conectar registry a la red de kind ─────────────────────
echo ""
echo "🔗 [3/6] Conectando registry a la red de kind..."
docker network connect kind registry 2>/dev/null || echo "   Ya estaba conectado."

# ─── 4. Build y push de imágenes ──────────────────────────────
echo ""
echo "🐳 [4/6] Construyendo y subiendo imágenes..."
docker build -t localhost:5000/counter-web:1.0 ./web
docker push localhost:5000/counter-web:1.0

docker build -t localhost:5000/counter-nginx:1.0 ./nginx
docker push localhost:5000/counter-nginx:1.0

# ─── 5. Secret y manifiestos ──────────────────────────────────
echo ""
echo "🔑 [5/6] Aplicando secret y manifiestos k8s..."
kubectl create secret generic flask-secret \
  --from-literal=secret-key='clave-super-secreta' \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f k8s/

# ─── 6. Esperar a que los pods estén Ready ────────────────────
echo ""
echo "⏳ [6/6] Esperando a que los pods estén Running..."
kubectl wait --for=condition=ready pod --all --timeout=120s

echo ""
kubectl get pods -o wide

# ─── Port-forward ─────────────────────────────────────────────
echo ""
echo "✅ ¡Todo listo! Exponiendo la app en http://localhost:8080"
echo "   (Ctrl+C para detener)"
echo ""
kubectl port-forward service/nginx 8080:80
