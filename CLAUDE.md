# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Bootstrap code for `bradfordwagner`'s personal Kubernetes homelab. It stands up a local `kind` cluster, uses Terraform to seed the secrets/namespaces ArgoCD needs, and then hands off to ArgoCD (GitOps, "app of apps" pattern) to install and manage everything else. Almost none of the actual application code lives here — this repo mostly contains Application/ApplicationSet manifests that point ArgoCD at other repos (`deploy-argocd`, `deploy-chart-vault`, `chart-vault-k8s-auth`, `chart-namespaces`, `chart-docker-buildkit`, `argo-helm`, etc.).

## Commands

All common workflows are driven through `Taskfile.yml` (https://taskfile.dev). Env vars (`KUBECONFIG`, `VAULT_ADDR`, `kv2_path`) and secrets (from `.secrets.sh`, gitignored) are loaded automatically by Task.

- `task cluster_create` (alias `task cc`): full bootstrap — `kind.sh create` → `terraform init` → `terraform apply -auto-approve` → `startup.sh`. This is the primary end-to-end setup flow.
- `task cluster_delete` (alias `task cd`): `kind.sh delete` — tears down the local kind cluster.
- `task kubernetes_apply` (alias `task ka`): `kubectl apply -f ./argocd/bootstrap` — (re)applies the ArgoCD app-of-apps root Application.
- `task kubernetes_delete` (alias `task kd`): `kubectl delete -f ./argocd/bootstrap`.
- `task vault_write_secrets` (alias `task vws`): pushes `.secrets.sh` / `.certificate` / `.private_key` into Vault KV at `secret/tf.cicd`.
- `task vault_read_secrets` (alias `task vrs`): pulls those same secrets back out of Vault into local gitignored files.

There is no lint/test/build tooling in this repo (no CI workflows, no test suite) — validation is "does the cluster come up healthy."

Standard Terraform commands (`terraform init`, `terraform plan`, `terraform apply`) work directly against the root module; state is local (`backend.tf`).

## Architecture / bootstrap flow

The pieces execute in this order, each depending on the previous:

1. **`kind.sh create`** — creates a local `kind` cluster named `admin`, with hardcoded NodePort mappings for Vault (`30003`) and ArgoCD (`30001`) and `certSANs` for external access. Kubeconfig goes to `~/.kube/admin`; an "internal" (in-cluster-reachable) kubeconfig + split-out CA/server files go to `~/.kube/kind/internal/admin*`. These internal files are consumed later by `main.tf` (`kubernetes_secret.admin_auth_config`) and by the Vault k8s auth ApplicationSet (`admin_auth_config` secret, `auth/kubernetes/{{cluster}}`).
2. **`terraform apply`** (`main.tf`, using the `kubernetes.admin` provider aliased to `~/.kube/admin`) — creates the `argocd` / `argo-workflows` / `vault` namespaces and seeds four `kubernetes_secret`s Vault needs before it can start: `keyvault` (Azure Key Vault auto-unseal creds, sourced from an `azuread_service_principal` data source + `var.vault_sp_secret`), `k8s-auth-config` (cluster CA/server/AppRole role_id+secret_id, for Vault's k8s auth backend), `storage` (Vault's Azure blob storage backend config, `config.hcl`), and `tls` (Vault's TLS cert/key, read from local gitignored `.certificate`/`.private_key`). Terraform variables (`vault_storage_key`, `vault_sp_secret`, `role_id`, `secret_id`) are expected to come from the environment/tfvars — not hardcoded.
3. **`startup.sh`** — installs ArgoCD itself via `kubectl apply -k` against the external `deploy-argocd` repo (not through Terraform/GitOps, since ArgoCD has to exist before it can manage itself), waits for `argocd-server`/`argocd-redis`, then logs in over a port-forward and resets the admin password. It creates two secrets ArgoCD apps depend on: `login` (ArgoCD admin creds, used later by the init-cluster Workflow) and `contexts` (kubeconfigs from `~/.kube/kind/internal/`, used to register clusters with ArgoCD). It then applies `argocd/apps/argo_workflows/appset.yaml` directly (bypassing GitOps bootstrap ordering, since Argo Workflows must exist to run the next step) and finally submits `workflows/init_clusters.yaml` to register kind clusters as ArgoCD cluster contexts via `argocd cluster add`.
4. **`argocd/bootstrap/bootstrap_apps.yaml`** — the GitOps root: an ArgoCD `Application` (sync-wave `2`) that recursively syncs everything under `argocd/apps/`, i.e. the actual app-of-apps. Applied via `task ka`.

### ArgoCD apps (`argocd/apps/`)

Each subdirectory is an `Application` or `ApplicationSet` pointing at an external chart repo. **Sync waves (`argocd.argoproj.io/sync-wave` annotation) encode real dependency ordering** — check/preserve them when adding or reordering apps:

- `namespaces/appset.yaml` (wave 0) — creates namespaces via `chart-namespaces`.
- `argo_workflows/appset.yaml` (wave 0) — Argo Workflows via upstream `argo-helm`, targeted at every cluster *except* `admin` (see the `NotIn` cluster-label selector — `admin`'s Argo Workflows install happens outside GitOps, in `startup.sh`).
- `vault/appset.yaml` (wave 1) — Vault via `deploy-chart-vault`, injector disabled, `authPath` templated per cluster.
- `vault/k8s_auth.yaml` (wave 2) — `chart-vault-k8s-auth`, configures Vault's k8s auth backend.
- `argocd/app.yaml` (no wave) — ArgoCD managing itself via `deploy-argocd` (GitOps takeover after the imperative bootstrap in step 3).
- `docker_buildkit/app.yaml` (wave 5) — `chart-docker-buildkit`, explicitly deployed last since it depends on tier-1 infra (Argo Workflows) being ready.

ApplicationSets that target multiple clusters use a `list` generator with one `admin`-cluster entry today, but are structured (`{{cluster}}` templating) to add more clusters later.

### Secrets handling

Nothing sensitive is committed. `.secrets.sh`, `.certificate`, `.private_key` are gitignored and round-trip through Vault KV (`secret/tf.cicd`) via `task vws` / `task vrs`. Terraform reads TLS material straight from these local files; Kubernetes secrets created by Terraform/ArgoCD are the only place credentials live at rest (in-cluster).
