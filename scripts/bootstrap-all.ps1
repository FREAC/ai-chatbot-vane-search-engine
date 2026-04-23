param(
  [string]$Model = "qwen3.6:27b",
  [switch]$SkipModelPull
)

$ErrorActionPreference = "Stop"

Write-Host "[1/4] Running Podman GPU setup..."
powershell -ExecutionPolicy Bypass -File "$PSScriptRoot\setup-podman-gpu.ps1"

Write-Host "[2/4] Starting Vane + Ollama stack..."
powershell -ExecutionPolicy Bypass -File "$PSScriptRoot\run-podman-gpu-stack.ps1"

if (-not $SkipModelPull) {
  Write-Host "[3/4] Pulling model: $Model"
  podman exec -it ollama-gpu ollama pull $Model
} else {
  Write-Host "[3/4] Skipping model pull"
}

Write-Host "[4/4] Final health checks..."
podman ps --format "table {{.Names}}`t{{.Status}}`t{{.Ports}}"
Write-Host "---"
podman exec vane curl -sS --connect-timeout 10 http://ollama-gpu:11434/api/tags
Write-Host "---"
podman exec -it ollama-gpu nvidia-smi

Write-Host ""
Write-Host "Bootstrap complete."
Write-Host "Vane: http://localhost:3000"
Write-Host "Ollama URL (inside Vane): http://ollama-gpu:11434"