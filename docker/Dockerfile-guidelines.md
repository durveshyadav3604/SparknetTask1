# Dockerfile Best Practices

This document outlines best practices for creating secure and optimized Dockerfiles for the Baby Products application.

## General Principles

1. **Use Multi-Stage Builds**
   - Separate build and runtime environments
   - Reduces final image size
   - Improves security by excluding build tools from production

2. **Use Specific Base Image Tags**
   - Avoid `latest` tag
   - Use specific version tags (e.g., `node:18-alpine`)
   - Prefer Alpine Linux for smaller images

3. **Minimize Layers**
   - Combine RUN commands where possible
   - Use `&&` to chain commands
   - Clean up package manager caches in the same layer

4. **Run as Non-Root User**
   - Create and use non-root user
   - Reduces security risks
   - Follow principle of least privilege

5. **Use .dockerignore**
   - Exclude unnecessary files from build context
   - Reduces build time and image size
   - Prevents sensitive files from being included

## Security Best Practices

1. **Keep Base Images Updated**
   - Regularly update base images
   - Scan images for vulnerabilities
   - Use official images from trusted sources

2. **Minimize Attack Surface**
   - Only install necessary packages
   - Remove package managers after installation
   - Use minimal base images (Alpine)

3. **Handle Secrets Properly**
   - Never hardcode secrets in Dockerfiles
   - Use environment variables or secret management
   - Use build arguments for non-sensitive configuration

4. **Health Checks**
   - Implement health checks for all services
   - Helps with container orchestration
   - Enables automatic recovery

## Optimization Tips

1. **Layer Ordering**
   - Copy package files first
   - Install dependencies before copying source code
   - Leverages Docker layer caching

2. **Cache Dependencies**
   - Install dependencies in separate layer
   - Only rebuild when dependencies change
   - Significantly speeds up builds

3. **Clean Up**
   - Remove package manager caches
   - Remove temporary files
   - Use `--no-cache` flag when needed

## Example Structure

```dockerfile
# Stage 1: Build
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .

# Stage 2: Production
FROM node:18-alpine
WORKDIR /app
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --chown=nodejs:nodejs . .
USER nodejs
EXPOSE 5000
CMD ["node", "server.js"]
```

## References

- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [OWASP Docker Security](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)


