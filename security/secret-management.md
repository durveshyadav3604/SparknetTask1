# Secret Management Strategy

This document outlines the secret management strategy for the Bags Luggage application deployed on Azure.

## Overview

Secrets and sensitive configuration should never be committed to version control. This document describes how to securely manage secrets in both CI/CD pipelines and runtime environments.

## CI/CD Secrets (GitHub Actions)

### GitHub Secrets

Store the following secrets in GitHub repository settings (Settings → Secrets and variables → Actions):

#### Required Secrets

1. **AZURE_CREDENTIALS**
   - Service Principal credentials for Azure authentication
   - Format: JSON with `clientId`, `clientSecret`, `subscriptionId`, `tenantId`
   - How to create:
     ```bash
      az ad sp create-for-rbac --name "bags-luggage-sp" \
         --role contributor \
         --scopes /subscriptions/{subscription-id} \
         --sdk-auth
     ```

2. **AZURE_RESOURCE_GROUP**
   - Name of the Azure resource group
   - Example: `bagsluggage-rg-dev`

3. **AZURE_LOCATION**
   - Azure region (optional, defaults to `eastus`)
   - Example: `eastus`

4. **ACR_NAME**
   - Azure Container Registry name
   - Example: `bagsluggageacrdev`

5. **AZURE_CLIENT_ID**
   - Service Principal Client ID for ACR authentication

6. **AZURE_CLIENT_SECRET**
   - Service Principal Client Secret for ACR authentication

7. **CONTAINER_APP_ENV**
   - Container Apps Environment name
   - Example: `bagsluggage-env-dev`

### Usage in GitHub Actions

Secrets are accessed in workflows using:
```yaml
${{ secrets.SECRET_NAME }}
```

## Runtime Secrets (Azure)

### Azure Key Vault (Recommended for Production)

For production environments, use Azure Key Vault to store secrets:

1. **Create Key Vault**
   ```bash
    az keyvault create \
       --name bags-luggage-kv \
       --resource-group bagsluggage-rg-dev \
       --location eastus
   ```

2. **Store Secrets**
   ```bash
    az keyvault secret set \
       --vault-name bags-luggage-kv \
       --name "MongoDBConnectionString" \
       --value "mongodb://..."
   ```

3. **Grant Access to Container Apps**
   - Use Managed Identity
   - Assign Key Vault access policy

4. **Reference in Container Apps**
   - Use Key Vault references in environment variables
   - Format: `@Microsoft.KeyVault(SecretUri=https://...vault.azure.net/secrets/...)`

### Environment Variables (Development)

For development, use environment variables in Container Apps:

```bash
   az containerapp update \
   --name backend \
   --resource-group bagsluggage-rg-dev \
   --set-env-vars "MONGO_URI=..." "PORT=5000"
```

## Application Configuration

### Backend (.env file - NOT committed)

```env
PORT=5000
MONGO_URI=mongodb://...
NODE_ENV=production
```

### Frontend (.env file - NOT committed)

```env
REACT_APP_API_URL=https://backend-url.azurecontainerapps.io
```

## Best Practices

1. **Never Commit Secrets**
   - Add `.env` to `.gitignore`
   - Use `.env.example` as template
   - Review commits before pushing

2. **Rotate Secrets Regularly**
   - Rotate service principal credentials quarterly
   - Update database connection strings when changed
   - Revoke old credentials immediately

3. **Use Least Privilege**
   - Grant minimum required permissions
   - Use separate service principals for different environments
   - Limit Key Vault access to specific identities

4. **Monitor Secret Access**
   - Enable Key Vault logging
   - Review access logs regularly
   - Set up alerts for suspicious activity

5. **Use Managed Identities**
   - Prefer Managed Identities over service principals
   - Eliminates need to store credentials
   - Automatically rotated by Azure

## Secret Rotation Process

1. Generate new secret
2. Update in Key Vault or GitHub Secrets
3. Update application configuration
4. Test deployment
5. Revoke old secret
6. Document rotation date

## Emergency Procedures

If a secret is compromised:

1. **Immediately rotate the secret**
2. **Revoke access for compromised credential**
3. **Review access logs for unauthorized use**
4. **Notify security team**
5. **Update all systems using the secret**
6. **Document incident**

## References

- [Azure Key Vault Documentation](https://docs.microsoft.com/azure/key-vault/)
- [GitHub Secrets Documentation](https://docs.github.com/actions/security-guides/encrypted-secrets)
- [Azure Managed Identities](https://docs.microsoft.com/azure/active-directory/managed-identities-azure-resources/)


