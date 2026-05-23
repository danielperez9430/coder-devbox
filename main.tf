terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
    }
    docker = {
      source  = "kreuzwerker/docker"
    }
  }
}

variable "coder_agent_token" {
  type      = string
  sensitive = true
  default   = ""
  nullable  = true
}

provider "coder" {}

data "coder_provisioner" "me" {}

data "coder_workspace" "me" {}

provider "docker" {}

data "coder_parameter" "node_version" {
  name         = "Node.js version"
  description  = "Node.js version to install via fnm"
  type         = "string"
  default      = "22"
  mutable      = true
  icon         = "/emojis/1f9f1.png"

  option {
    name  = "Latest LTS"
    value = "--lts"
  }
  option {
    name  = "Node 24"
    value = "24"
  }
  option {
    name  = "Node 22 LTS"
    value = "22"
  }
  option {
    name  = "Node 20 LTS"
    value = "20"
  }
}

resource "coder_agent" "main" {
  arch = data.coder_provisioner.me.arch
  os   = "linux"
  auth = "token"

  env = {
    FNM_DIR = "/home/coder/.local/share/fnm"
  }

  startup_script = <<-EOT
    #!/bin/bash
    set -e

    # Start Docker daemon in background
    sudo dockerd >/tmp/dockerd.log 2>&1 &
    sleep 2

    # Initialize fnm
    export FNM_DIR="/home/coder/.local/share/fnm"
    export PATH="$FNM_DIR:$PATH"

    NODE_VERSION="${data.coder_parameter.node_version.value}"

    # Install Node.js and set default
    fnm install "$${NODE_VERSION}"
    if [ "$${NODE_VERSION}" = "--lts" ]; then
      fnm default lts-latest
      eval "`fnm env --shell bash`"
      fnm use lts-latest
    else
      fnm default "$${NODE_VERSION}"
      eval "`fnm env --shell bash`"
      fnm use "$${NODE_VERSION}"
    fi

    # Start code-server in background
    code-server \
      --bind-addr 0.0.0.0:8080 \
      --auth none \
      --disable-telemetry \
      /home/coder/project \
      >/tmp/code-server.log 2>&1 &
  EOT
}

resource "docker_image" "dev_image" {
  name = "coder-dev:latest"
  build {
    context    = "${path.module}"
    dockerfile = "Dockerfile"
    tag        = ["coder-dev:latest"]
  }
}

resource "docker_container" "workspace" {
  image = docker_image.dev_image.name
  name  = "coder-${lower(data.coder_workspace.me.name)}"
  hostname = lower(data.coder_workspace.me.name)

  privileged = true

  env = [
    "CODER_AGENT_TOKEN=${coder_agent.main.token}",
  ]

  command = ["sh", "-c", coder_agent.main.init_script]

  labels {
    label = "coder.agent.token"
    value = coder_agent.main.token
  }
}

resource "coder_app" "code-server" {
  agent_id     = coder_agent.main.id
  slug         = "code-server"
  display_name = "VS Code"
  url          = "http://localhost:8080/?folder=/home/coder/project"
  icon         = "/icon/code.svg"
  subdomain    = false
  share        = "owner"
}
