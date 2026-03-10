# counter-k8s

Aplicación de demostración para aprender cómo Kubernetes escala y desescala pods automáticamente mediante el **Horizontal Pod Autoscaler (HPA)**.

> La aplicación en sí (un contador de visitas y clicks con Redis) es solo el pretexto. El objetivo real es observar en tiempo real cómo Kubernetes reacciona ante la carga.

---

## Arquitectura

```
Internet → nginx (1 pod) → web/Flask (1–8 pods) → Redis (1 pod)
```

| Componente | Imagen | Réplicas |
|------------|--------|----------|
| nginx | custom (proxy inverso) | 1 (fija) |
| web | custom (Flask + Python) | 1–8 (autoscaling) |
| redis | redis:7-alpine | 1 (fija) |

Solo el pod `web` escala, ya que es el que recibe y procesa las peticiones HTTP.

---

## Requisitos previos

- [Docker](https://docs.docker.com/get-docker/) instalado y en ejecución
- Acceso a internet (para descargar imágenes y herramientas)
- Linux o GitHub Codespaces (recomendado)

> `kind` y `kubectl` se instalan automáticamente si no están presentes.

---

## Arranque

```bash
chmod +x start.sh
./start.sh
```

El script realiza los siguientes pasos:

1. Instala `kind` y `kubectl` si no están disponibles
2. Crea un clúster Kubernetes local con `kind`
3. Configura el HPA sync period a 10 segundos (más reactivo)
4. Levanta un registry Docker local
5. Construye y publica las imágenes
6. Despliega todos los manifiestos en Kubernetes
7. Expone la aplicación en `http://localhost:8080`

---

## Observar el autoscaling

Abre dos terminales en paralelo.

### Terminal 1 — Observar los pods en tiempo real

```bash
kubectl get pods -w
```

### Terminal 2 — Observar el HPA en tiempo real

```bash
kubectl get hpa -w
```

Verás columnas como estas:

```
NAME      REFERENCE        TARGETS        MINPODS   MAXPODS   REPLICAS
web-hpa   Deployment/web   cpu: 5%/20%    1         8         1
```

- **TARGETS**: uso actual de CPU vs umbral configurado
- **REPLICAS**: número de pods activos en este momento

---

## Generar carga (escalar)

Ejecuta este comando para simular tráfico intenso:

```bash
kubectl run -it --rm load-generator --image=busybox -- /bin/sh -c \
  "while true; do wget -q -O- http://web:5000; done"
```

En 10–30 segundos verás cómo:

1. La CPU de los pods `web` sube por encima del 20%
2. El HPA decide añadir réplicas
3. Aparecen nuevos pods `web-xxx` en estado `Running`

Para detener la carga: `Ctrl+C`

---

## Observar el desescalado

Una vez detenida la carga, el HPA esperará un periodo de estabilización antes de reducir réplicas (para evitar fluctuaciones). Con la configuración actual:

- **Scale up**: reacciona en ~10–30 segundos
- **Scale down**: reacciona en ~20 segundos tras caer la CPU

Podrás ver cómo los pods van pasando a `Terminating` y desaparecen hasta volver a 1 réplica.

---

## Configuración del HPA

El HPA está definido en `k8s/web-hpa.yaml`:

```yaml
minReplicas: 1       # mínimo de pods en reposo
maxReplicas: 8       # máximo de pods bajo carga
averageUtilization: 20  # escala cuando la CPU supera el 20%
stabilizationWindowSeconds: 20  # espera antes de desescalar
```

Puedes modificar estos valores y aplicar los cambios con:

```bash
kubectl apply -f k8s/web-hpa.yaml
```

---

## Comandos útiles

```bash
# Ver todos los pods y en qué nodo corren
kubectl get pods -o wide

# Ver el estado del HPA
kubectl get hpa

# Ver el uso de CPU y memoria de cada pod
kubectl top pods

# Ver logs de un pod concreto
kubectl logs <nombre-del-pod>

# Ver detalles y eventos del HPA
kubectl describe hpa web-hpa
```

---

## Detener la aplicación

```bash
# Detener el port-forward: Ctrl+C en la terminal del start.sh

# Eliminar todos los recursos de Kubernetes
kubectl delete -f k8s/

# Eliminar el clúster kind completo
kind delete cluster
```