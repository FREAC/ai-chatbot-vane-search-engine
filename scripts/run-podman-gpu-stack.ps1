param(
  [string]$NetworkName = "ai-net",
  [string]$VaneImage = "itzcrazykns1337/vane:latest",
  [string]$OllamaImage = "ollama/ollama:latest"
)

$ErrorActionPreference = "Stop"

Write-Host "[1/5] Creating network if missing..."
podman network exists $NetworkName 2>$null
if ($LASTEXITCODE -ne 0) {
  podman network create $NetworkName | Out-Null
}

Write-Host "[2/5] Ensuring volumes exist..."
podman volume exists vane-data 2>$null
if ($LASTEXITCODE -ne 0) {
  podman volume create vane-data | Out-Null
}

podman volume exists ollama-data 2>$null
if ($LASTEXITCODE -ne 0) {
  podman volume create ollama-data | Out-Null
}

Write-Host "[3/5] Recreating ollama-gpu container..."
podman rm -f ollama-gpu 2>$null | Out-Null
podman run -d `
  --name ollama-gpu `
  --network $NetworkName `
  --device nvidia.com/gpu=all `
  -p 11434:11434 `
  -v ollama-data:/root/.ollama `
  --restart unless-stopped `
  $OllamaImage | Out-Null

Write-Host "[4/5] Recreating vane container..."
podman rm -f vane 2>$null | Out-Null
podman run -d `
  --name vane `
  --network $NetworkName `
  -p 3000:3000 `
  -v vane-data:/home/vane/data `
  --restart unless-stopped `
  $VaneImage | Out-Null

Write-Host "[5/5] Verifying Ollama API from Vane container..."
podman exec vane curl -sS --connect-timeout 10 http://ollama-gpu:11434/api/tags | Out-Host

Write-Host ""
Write-Host "Stack is up."
Write-Host "Vane: http://localhost:3000"
Write-Host "Ollama API (from Vane): http://ollama-gpu:11434"