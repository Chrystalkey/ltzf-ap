# Deployment Guide

This guide explains how to deploy the LTZF Administration Panel using Docker.

## Prerequisites

- Docker
- Docker Compose (optional, for easier deployment)

## Quick Start with Docker Compose

1. **Clone the repository and navigate to the project directory:**
   ```bash
   cd ltzf_ap
   ```

2. **Set up environment variables:**
   ```bash
   # Generate a secret key base
   mix phx.gen.secret
   
   # Create a .env file with your configuration
   cat > .env << EOF
   SECRET_KEY_BASE=your-generated-secret-key-base
   PHX_HOST=your-domain.com
   DEFAULT_BACKEND_URL=https://your-api-backend.com
   EOF
   ```

3. **Build and start the application:**
   ```bash
   docker-compose up -d
   ```

4. **Access the application:**
   Open your browser and navigate to `http://localhost:4000`

## Manual Docker Deployment

1. **Build the Docker image:**
   ```bash
   docker build -t ltzf-ap .
   ```

2. **Run the container:**
   ```bash
   docker run -d \
     --name ltzf-ap \
     -p 4000:4000 \
     -e PHX_SERVER=true \
     -e SECRET_KEY_BASE=your-secret-key-base \
     -e PHX_HOST=your-domain.com \
     -e DEFAULT_BACKEND_URL=https://your-api-backend.com \
     ltzf-ap
   ```

## Environment Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `SECRET_KEY_BASE` | Secret key for signing cookies and tokens | Yes | - |
| `PHX_HOST` | Hostname for the application | No | localhost |
| `PORT` | Port to run the application on | No | 4000 |
| `DEFAULT_BACKEND_URL` | Default backend URL for login screen | No | - |
| `DNS_CLUSTER_QUERY` | DNS cluster query for clustering | No | - |

## Production Deployment

For production deployment, consider the following:

1. **Use a reverse proxy (nginx/traefik)** for SSL termination and load balancing
2. **Set up proper logging** with log aggregation
3. **Configure monitoring** and alerting
4. **Use secrets management** for sensitive environment variables
5. **Set up backups** for any persistent data

### Example with Nginx Reverse Proxy

```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  ltzf-ap:
    build: .
    environment:
      - PHX_SERVER=true
      - SECRET_KEY_BASE=${SECRET_KEY_BASE}
      - PHX_HOST=${PHX_HOST}
      - DEFAULT_BACKEND_URL=${DEFAULT_BACKEND_URL}
    networks:
      - app-network
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - ltzf-ap
    networks:
      - app-network
    restart: unless-stopped

networks:
  app-network:
    driver: bridge
```

## Health Checks

The application includes a health check that verifies the web server is responding. You can check the health status with:

```bash
docker inspect --format='{{.State.Health.Status}}' ltzf-ap
```

## Troubleshooting

### Common Issues

1. **Application won't start:**
   - Check that `SECRET_KEY_BASE` is set
   - Verify all required environment variables are configured

2. **Can't connect to the application:**
   - Ensure port 4000 is exposed and not blocked by firewall
   - Check that `PHX_HOST` matches your domain

3. **Assets not loading:**
   - Verify the build process completed successfully
   - Check that assets were compiled during the Docker build

### Logs

View application logs:
```bash
# With docker-compose
docker-compose logs -f ltzf-ap

# With docker
docker logs -f ltzf-ap
```

## Security Considerations

1. **Never commit secrets** to version control
2. **Use HTTPS** in production with proper SSL certificates
3. **Run the container as non-root user** (already configured in Dockerfile)
4. **Regularly update** the base images and dependencies
5. **Scan images** for vulnerabilities before deployment

## Scaling

For horizontal scaling, you can run multiple instances behind a load balancer:

```bash
# Scale to 3 instances
docker-compose up -d --scale ltzf-ap=3
```

Note: Ensure your application is stateless and can handle multiple instances. 