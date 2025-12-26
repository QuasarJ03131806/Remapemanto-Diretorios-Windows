<#
.SYNOPSIS
    Copia a pasta Users de uma unidade externa para C:\Users mantendo a hierarquia.
    Solicita elevação de privilégios (Administrador) automaticamente.

.DESCRIPTION
    Este script foi desenvolvido para migração de dados de usuários.
    Ele utiliza o Robocopy para uma cópia robusta e rápida.

.NOTES
    Autor: Mizael Souto
    Empresa: Uppertec
    Data: 2025-12-22
#>

# 1. Garante execução como Administrador (Solicita permissão uma única vez)
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Solicitando permissão de Administrador para acessar arquivos..." -ForegroundColor Yellow
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

Clear-Host
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   MIGRAÇÃO DE USUÁRIOS WINDOWS" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 2. Solicita a letra da unidade de origem
$driveLetter = Read-Host "Digite a LETRA da unidade de origem (ex: D, E, F) - apenas a letra"

# Remove dois pontos ou barras extras caso o usuário digite "D:" ou "D:\"
$driveLetter = $driveLetter -replace ":|\\|/", ""

if ([string]::IsNullOrWhiteSpace($driveLetter)) {
    Write-Error "Nenhuma letra de unidade fornecida."
    Pause
    Exit
}

$sourcePath = "${driveLetter}:\Users"
$destPath = "C:\Users"

# 3. Valida se a origem existe
if (-not (Test-Path -Path $sourcePath)) {
    Write-Error "A pasta de origem não foi encontrada: $sourcePath"
    Write-Host "Verifique se a letra da unidade está correta e se a pasta 'Users' existe nela." -ForegroundColor Red
    Pause
    Exit
}

Write-Host "Origem: $sourcePath" -ForegroundColor Green
Write-Host "Destino: $destPath" -ForegroundColor Green
Write-Host ""
Write-Host "Iniciando cópia com Robocopy..." -ForegroundColor Yellow
Write-Host "Isso pode levar algum tempo dependendo do tamanho dos arquivos." -ForegroundColor Gray
Write-Host ""

# 4. Executa o Robocopy
# /E :: copia subpastas, incluindo as vazias.
# /COPY:DAT :: copia Dados, Atributos e Carimbos de tempo (Time).
# /R:0 :: 0 tentativas em caso de erro (pula arquivos travados/inacessíveis para não travar o script).
# /W:0 :: espera 0 segundos entre tentativas.
# /XJ :: exclui pontos de junção (Junction Points) para evitar loops infinitos comuns em pastas de usuários (ex: AppData).

$robocopyParams = @(
    "$sourcePath",
    "$destPath",
    "/E",
    "/COPY:DAT",
    "/R:0",
    "/W:0",
    "/XJ",
    "/TEE",        # Exibe saída no console
    "/NP"          # Não exibe porcentagem de progresso (para log mais limpo)
)

# Executa comando
& robocopy @robocopyParams

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   PROCESSO CONCLUÍDO" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Verifique acima se houve erros (arquivos ignorados costumam ser normais se estiverem em uso ou bloqueados)."
Write-Host ""
Pause
