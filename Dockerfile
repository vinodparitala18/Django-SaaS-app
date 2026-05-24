# Set the python version as a build-time argument
ARG PYTHON_VERSION=3.12-slim-bullseye
FROM python:${PYTHON_VERSION}

# Create a virtual environment
RUN python -m venv /opt/venv

# Set virtual environment path
ENV PATH="/opt/venv/bin:$PATH"

# Python environment settings
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Upgrade pip
RUN pip install --upgrade pip

# Install OS dependencies
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libjpeg-dev \
    libcairo2 \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Create application directory
RUN mkdir -p /code

# IMPORTANT:
# manage.py exists inside src/myproject
WORKDIR /code/myproject

# Copy requirements first
COPY requirements.txt /tmp/requirements.txt

# Install Python dependencies
RUN pip install -r /tmp/requirements.txt

# Install production packages
RUN pip install gunicorn whitenoise psycopg2-binary --upgrade

# Copy project files
COPY ./src /code

# Environment variables
ARG DJANGO_SECRET_KEY
ENV DJANGO_SECRET_KEY=${DJANGO_SECRET_KEY}

ARG DJANGO_DEBUG=0
ENV DJANGO_DEBUG=${DJANGO_DEBUG}

# Optional rav setup
COPY ./rav.yaml /tmp/rav.yaml

# Uncomment only if rav works correctly
# RUN rav download staticfiles_prod -f /tmp/rav.yaml

# Collect static files
RUN python manage.py collectstatic --noinput

# Django project name
ARG PROJ_NAME="myproject"

# Create startup script
RUN printf "#!/bin/bash\n" > /code/myproject/paracord_runner.sh && \
    printf "RUN_PORT=\"\${PORT:-8000}\"\n\n" >> /code/myproject/paracord_runner.sh && \
    printf "python manage.py migrate --no-input\n" >> /code/myproject/paracord_runner.sh && \
    printf "gunicorn ${PROJ_NAME}.wsgi:application --bind 0.0.0.0:\$RUN_PORT\n" >> /code/myproject/paracord_runner.sh

# Make script executable
RUN chmod +x /code/myproject/paracord_runner.sh

# Cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Expose port
EXPOSE 8000

# Start application
CMD ["./paracord_runner.sh"]
