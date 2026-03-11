FROM python:3.11-slim

# Establecer directorio de trabajo ANTES de todo
WORKDIR /app

# Copiar archivos
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .
COPY templates/ ./templates/

# Asegurar que estamos en el directorio correcto y Python puede encontrar los módulos
ENV PYTHONPATH=/app
ENV FLASK_APP=app.py

# Verificación
RUN python3 -c "import sys; print('Python path:', sys.path)" && \
    python3 -c "import os; print('CWD:', os.getcwd()); print('Files:', os.listdir('.'))" && \
    python3 -c "import app; print('App imported successfully')"

# ✅ Medida de seguridad: Crear usuario sin privilegios y asignar ownership de /app
RUN addgroup --system appgroup && \
    adduser --system --ingroup appgroup appuser && \
    chown -R appuser:appgroup /app

# ✅ Medida de seguridad: Cambiar al usuario sin privilegios
USER appuser

EXPOSE 5000

# Usar python -m gunicorn para asegurar que use el Python del sistema
CMD ["python3", "-m", "gunicorn", "--bind", "0.0.0.0:5000", "--workers", "1", "--timeout", "60", "app:app"]