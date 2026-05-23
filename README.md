# coder-devbox

Browser-based development environment with VS Code, Docker-in-Docker, and fnm for Node.js version management.

## What's included

- **[code-server](https://github.com/coder/code-server)** — VS Code in the browser, dark theme pre-configured
- **[fnm](https://github.com/Schniz/fnm)** — Fast Node Manager, initialized in every terminal
- **Docker-in-Docker** — full Docker daemon inside the workspace (`fuse-overlayfs` storage driver)
- **docker compose** — Buildx and Compose plugins included
- `nano`, `git`, `curl`, `wget`, `sudo` (passwordless for the `coder` user)

## Parameters

| Parameter | Options | Default |
|---|---|---|
| Node.js version | Latest LTS, Node 24, Node 22 LTS, Node 20 LTS | Node 22 LTS |

## Prerequisites

- [Coder](https://coder.com) server running (v2.x)
- Docker running on the Coder provisioner host
- Terraform (for `terraform init` before first push)

## Usage

```bash
# First time — generate the provider lockfile
terraform init

# Push the template
coder templates push coder-devbox

# Create a workspace from the dashboard, or via CLI:
coder create --template coder-devbox my-workspace
```

## File structure

```
├── main.tf                    # Coder template (agent, container, apps)
├── Dockerfile                 # Image with code-server, fnm, Docker
├── code-server-settings.json  # VS Code defaults (theme, etc.)
├── .gitignore
└── README.md
```
