# Pattern - Using AKS H100 GPU Cluster Deployment with Bicep

This repository automates the deployment of a private Azure Kubernetes Service (AKS) cluster with NVIDIA H100 GPUs using Bicep and installs the NVIDIA GPU Operator for GPU workload support.

## Features

- Deploys a private AKS cluster using `main.bicep`
- Sets up an Azure Container Registry (ACR)
- Installs the NVIDIA GPU Operator using Helm
- Verifies GPU access with a test pod using `nvidia-smi`

## Prerequisites

- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/)
- [Bicep CLI](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install)
- [Helm](https://helm.sh/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [GitHub CLI (optional)](https://cli.github.com/)

## Usage

Run the deployment script:

```bash
chmod +x run.sh
./run.sh
```

Update these variables inside the script to match your environment:

```bash
RESOURCE_GROUP="rg-pvt-aks-h100"
LOCATION="eastus2"
PARAM_REGISTRY_NAME="gbbpvt"
PARAM_CLUSTER_NAME="pvt-aks-h100"
```

## Repository Structure:

- main.bicep – Main Bicep template with modular infrastructure
- pod-check-nvidia-smi.yaml – Pod spec to validate NVIDIA GPU access
- run.sh – Script to provision infrastructure and install GPU operator
- .github/workflows/deploy.yml – GitHub Actions workflow for CI deployment

## GitHub Actions Integration

To use the GitHub Actions workflow in this repository, follow these steps:

1. **Fork this repository** to your GitHub account.
1. **Create a user-assigned managed identity** to authenticate from GitHub Actions.
1. Create a **federated identity credential** on the user id so GitHub can issue tokens.
1. Set the **AZURE_CREDENTIALS** secret in your GitHub repository using the output below.

Here is an example using User Assigned Managed Identity

1. Create the User-Assigned Managed Identity

    ```bash
    MI_NAME="github-actions-identity"
    RESOURCE_GROUP_MI="rg-github-actions-identity"
    LOCATION="eastus2"
    REGISTRY_NAME="gbbpvt"
    
    # Managed ID resource group
    az group create \
      --name "$RESOURCE_GROUP_MI" \
      --location "$LOCATION"

    az identity create \
      --name "$MI_NAME" \
      --resource-group "$RESOURCE_GROUP_MI" \
      --location "$LOCATION"

    # deployment resource group
    RESOURCE_GROUP="rg-pvt-aks-h100"
    az group create \
      --name "$RESOURCE_GROUP" \
      --location "$LOCATION"
    ```

    Save these values:

    ```bash
    CLIENT_ID=$(az identity show -g "$RESOURCE_GROUP_MI" -n "$MI_NAME" --query clientId -o tsv)
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    TENANT_ID=$(az account show --query tenantId -o tsv)
    
    echo "Client ID: $CLIENT_ID"
    echo "Subscription ID: $SUBSCRIPTION_ID"
    echo "Tenant ID: $TENANT_ID"
    ```

1. Assign Role to the Identity

    Grant `Contributor` or a scoped role like `acrpull` if only pulling from ACR:

    ```bash
    MI_PRINCIPAL_ID=$(az identity show -g "$RESOURCE_GROUP_MI" -n "$MI_NAME" --query principalId -o tsv)
    
    # Assign "Contributor" to the MI
    az role assignment create \
      --assignee-object-id "$MI_PRINCIPAL_ID" \
      --role Contributor \
      --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP
    
    ACR_ID=$(az acr show -n "$REGISTRY_NAME" -g "$RESOURCE_GROUP" --query id -o tsv)

    # Assign "User Access Administrator" to allow role assignments
    az role assignment create \
      --assignee-object-id "$MI_PRINCIPAL_ID" \
      --role "User Access Administrator" \
      --scope "$ACR_ID"
    ```

1. Configure Federated Identity Credential for GitHub

    Replace `GITHUB_ORG` and `REPO` accordingly:

    ```bash
    GITHUB_ORG="appdevgbb"
    REPO="pattern-private-aks-gpu"
    az identity federated-credential create \
      --name github-actions \
      --identity-name "$MI_NAME" \
      --resource-group "$RESOURCE_GROUP_MI" \
      --issuer "https://token.actions.githubusercontent.com" \
      --subject "repo:$GITHUB_ORG/$REPO:ref:refs/heads/main" \
      --audiences "api://AzureADTokenExchange"
    ```

1. Create the **AZURE_CREDENTIALS** Secret for GitHub

    Generate the credentials JSON:

    ```bash
    cat <<EOF
    {
      "clientId": "$CLIENT_ID",
      "subscriptionId": "$SUBSCRIPTION_ID",
      "tenantId": "$TENANT_ID",
      "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
      "resourceManagerEndpointUrl": "https://management.azure.com/",
      "authorityHost": "https://login.microsoftonline.com",
      "clientCertificate": null,
      "clientCertificatePassword": null,
      "clientCertificateSendChain": null
    }
    EOF
    ```



# Get identity info
CLIENT_ID=$(az identity show -g "$RESOURCE_GROUP_MI" -n "$MI_NAME" --query clientId -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

echo ""
echo "✅ Copy the following values into your GitHub repository secrets:"
echo ""
echo "AZURE_CLIENT_ID=$CLIENT_ID"
echo "AZURE_TENANT_ID=$TENANT_ID"
echo "AZURE_SUBSCRIPTION_ID=$SUBSCRIPTION_ID"


Finally:

* Go to your GitHub repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

* Name it: `AZURE_CREDENTIALS`

* Paste the JSON output as the value

Once done, the GitHub Action (.github/workflows/deploy.yml) will be able to authenticate and deploy your infrastructure.