FROM python:3.12-slim

# Install uv for fast installs, then jaclang
RUN pip install --no-cache-dir uv && \
    uv tool install "jaclang==0.11.2" && \
    ln -s /root/.local/bin/jac /usr/local/bin/jac

WORKDIR /app

# Copy project definition first so dependency layer is cached
COPY jac.toml ./

# Install Python dependencies declared in jac.toml into the project venv
RUN jac install

# Copy application source (credentials file excluded via .dockerignore)
COPY main.jac firebase_app.py llm_agent.py ./

EXPOSE 6000

# Credentials path is set at runtime (not baked into the image).
# docker-compose.yml mounts the secret at /run/secrets/firebase_credentials.
CMD ["jac", "start", "main.jac", "--no_client"]
