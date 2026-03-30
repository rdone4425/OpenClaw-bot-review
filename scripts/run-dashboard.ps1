Param(
  [string]$Image = $(if ($env:IMAGE) { $env:IMAGE } else { "ghcr.io/rdone4425/openclaw-bot-review:main" }),
  [string]$ContainerName = $(if ($env:CONTAINER_NAME) { $env:CONTAINER_NAME } else { "openclaw-dashboard" }),
  [int]$HostPort = $(if ($env:HOST_PORT) { [int]$env:HOST_PORT } else { 3000 }),
  [string]$OpenclawHome = $(if ($env:OPENCLAW_HOME) { $env:OPENCLAW_HOME } else { "$env:USERPROFILE\\.openclaw" }),
  [switch]$ReadOnly
)

$ErrorActionPreference = "Stop"
$containerOpenclawHome = "/openclaw"
$configPath = Join-Path $OpenclawHome "openclaw.json"
$readonlyEnv = $env:OPENCLAW_READONLY

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
  throw "docker not found. Install Docker Desktop first."
}

if (-not (Test-Path -LiteralPath $configPath)) {
  throw "Missing: $configPath`nSet OPENCLAW_HOME to the host directory that contains openclaw.json."
}

Write-Host "Pulling image: $Image"
docker pull $Image | Out-Host

Write-Host "Removing existing container (if any): $ContainerName"
docker rm -f $ContainerName 2>$null | Out-Null

$volume = "$OpenclawHome`:$containerOpenclawHome"
if ($ReadOnly -or $readonlyEnv -eq "1") {
  $volume = "$volume`:ro"
}

Write-Host "Starting container: $ContainerName"
$id = docker run -d `
  --name $ContainerName `
  --restart unless-stopped `
  -p "$HostPort`:3000" `
  -e "OPENCLAW_HOME=$containerOpenclawHome" `
  -v $volume `
  $Image

Write-Host "OK"
Write-Host "URL: http://localhost:$HostPort"
Write-Host "Logs: docker logs -f $ContainerName"

