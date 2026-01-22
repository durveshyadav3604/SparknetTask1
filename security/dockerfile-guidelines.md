# Dockerfile Security Guidelines

This document provides security-specific guidelines for Dockerfile creation in the Baby Products application.

## Security Principles

### 1. Use Minimal Base Images

- Prefer Alpine Linux variants
- Smaller attack surface
- Fewer vulnerabilities
- Example: `node:18-alpine` instead of `node:18`

### 2. Run as Non-Root User

Always create and use a non-root user:

```dockerfile
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001
USER nodejs
```

### 3. Keep Images Updated

- Regularly update base images
- Use specific version tags
- Monitor for security updates
- Set up automated scanning

### 4. Minimize Installed Packages

- Only install what's needed
- Remove package managers after use
- Clean package caches

### 5. Use Multi-Stage Builds

- Separate build and runtime
- Exclude build tools from final image
- Reduces attack surface

## Security Checklist

- [ ] Base image uses specific version tag
- [ ] Running as non-root user
- [ ] No hardcoded secrets
- [ ] Minimal packages installed
- [ ] Package caches cleaned
- [ ] Health checks implemented
- [ ] .dockerignore configured
- [ ] Multi-stage build used
- [ ] Image scanned for vulnerabilities

## Common Vulnerabilities to Avoid

### 1. Secrets in Layers

**BAD:**
```dockerfile
ENV API_KEY=secret123
```

**GOOD:**
```dockerfile
ARG API_KEY
ENV API_KEY=$API_KEY
# Pass at build time: docker build --build-arg API_KEY=...
```

### 2. Running as Root

**BAD:**
```dockerfile
FROM node:18
CMD ["node", "server.js"]
```

**GOOD:**
```dockerfile
FROM node:18-alpine
RUN adduser -D nodejs
USER nodejs
CMD ["node", "server.js"]
```

### 3. Including Sensitive Files

**BAD:**
```dockerfile
COPY . .
```

**GOOD:**
```dockerfile
# Use .dockerignore
COPY package*.json ./
COPY src/ ./src/
```

## Scanning and Validation

### Trivy Scanning

Scan images with Trivy:
```bash
trivy image your-image:tag
```

### Docker Bench Security

Run Docker security audit:
```bash
docker run --rm --net host --pid host --userns host --cap-add audit_control \
  -e DOCKER_CONTENT_TRUST=$DOCKER_CONTENT_TRUST \
  -v /etc:/etc:ro \
  -v /usr/bin/containerd:/usr/bin/containerd:ro \
  -v /usr/bin/runc:/usr/bin/runc:ro \
  -v /usr/lib/systemd:/usr/lib/systemd:ro \
  -v /var/lib:/var/lib:ro \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  --label docker_bench_security \
  docker/docker-bench-security
```

## References

- [Docker Security Best Practices](https://docs.docker.com/develop/security-best-practices/)
- [OWASP Docker Security](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)


