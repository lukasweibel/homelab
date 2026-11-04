# Architecture

## Components

| Component | Responsibility | Location |
|---|---|---|
| Argo CD root application | Loads application definitions from the repository | `clusters/home-cluster/argocd` |
| Application manifests | Define Helm charts or repository paths for cluster applications | `clusters/home-cluster/argocd/apps` |
| Application charts and values | Define local workloads and image settings | `clusters/home-cluster/apps` |
| Host configuration | Defines services deployed to physical hosts | `infrastructure/hosts` |

## Data flow

Changes merged to the main branch are observed by Argo CD. Automated synchronization applies the declared cluster state.

## Key conventions

Repository changes are the source of truth. Avoid direct edits to live Kubernetes resources. Keep configuration changes scoped to the relevant manifests.
