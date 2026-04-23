param(
  [string]$MachineName = "podman-machine-default"
)

$ErrorActionPreference = "Stop"

Write-Host "[1/5] Checking Podman availability..."
if (-not (Get-Command podman -ErrorAction SilentlyContinue)) {
  throw "podman was not found in PATH. Install Podman first."
}

Write-Host "[2/5] Ensuring Podman machine is running..."
podman machine inspect $MachineName | Out-Null
$machines = podman machine list --format json | ConvertFrom-Json
$machine = $machines | Where-Object { $_.Name -eq $MachineName } | Select-Object -First 1
if (-not $machine) {
  throw "Podman machine '$MachineName' was not found."
}

$isRunning = $false
if ($machine.PSObject.Properties.Name -contains "Running") {
  $isRunning = [bool]$machine.Running
}
if (-not $isRunning) {
  podman machine start $MachineName | Out-Null
}

Write-Host "[3/5] Installing NVIDIA container toolkit in Podman machine..."
podman machine ssh "dnf -y install nvidia-container-toolkit"

Write-Host "[4/5] Generating CDI spec..."
podman machine ssh "mkdir -p /etc/cdi && nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml"

Write-Host "[5/5] Validating GPU in a test container..."
podman run --rm --device nvidia.com/gpu=all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi

Write-Host ""
Write-Host "GPU setup completed. Next steps:"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\\scripts\\run-podman-gpu-stack.ps1"
Write-Host "  podman exec -it ollama-gpu ollama pull qwen3.6:27b"
Write-Host "  podman exec -it ollama-gpu nvidia-smi"