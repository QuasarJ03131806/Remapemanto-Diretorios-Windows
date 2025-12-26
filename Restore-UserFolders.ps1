<#
.SYNOPSIS
    Restaura as pastas do usuário para o local original (C:\Users\...) e reverte alterações no registro.

.DESCRIPTION
    Este script reverte as alterações feitas pelo Redirect-UserFolders.ps1.
    Ele move os arquivos de volta para o perfil do usuário, remove as Junções (Junctions)
    e restaura as chaves de registro para os valores padrão (%USERPROFILE%).

.NOTES
    Autor: Mizael Souto
    Empresa: Uppertec
    Data: 2025-12-25
#>

# 1. Garante execução como Administrador
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Solicitando permissão de Administrador para restaurar configurações..." -ForegroundColor Yellow
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

Clear-Host
Write-Host "==========================================" -ForegroundColor Magenta
Write-Host "   RESTAURAÇÃO DE PASTAS DO USUÁRIO" -ForegroundColor Magenta
Write-Host "==========================================" -ForegroundColor Magenta
Write-Host "Este script moverá suas arquivos DE VOLTA para C:\Users\$env:USERNAME."
Write-Host "Junções serão removidas e o registro será resetado."
Write-Host ""

$currentUser = $env:USERNAME
$userProfilePath = "$env:USERPROFILE"
$userProfileConfig = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"

# Lista de pastas conhecidas (Mesma do script de redirecionamento)
$foldersToRestore = @(
    @{ RegName="Desktop";                                      DefaultName="Desktop" },
    @{ RegName="Personal";                                     DefaultName="Documents" },
    @{ RegName="{374DE290-BC0F-4445-838C-AB42E860FE27}";       DefaultName="Downloads" },
    @{ RegName="My Music";                                     DefaultName="Music" },
    @{ RegName="My Pictures";                                  DefaultName="Pictures" },
    @{ RegName="My Video";                                     DefaultName="Videos" }
)

Write-Host "AVISO: Certifique-se de que você tem espaço suficiente no disco C: para trazer os arquivos de volta!" -ForegroundColor Red
Write-Host ""
$confirm = Read-Host "Deseja iniciar a restauração AGORA? (S/N)"
if ($confirm -notmatch "S|s") { Exit }

# 1.1 Verificação de Arquivos em Uso (Navegadores)
$browsers = @("chrome", "msedge", "firefox", "opera", "brave")
$runningBrowsers = Get-Process -Name $browsers -ErrorAction SilentlyContinue

if ($runningBrowsers) {
    Write-Host ""
    Write-Host "ATENÇÃO: Navegadores detectados em execução!" -ForegroundColor Red
    $closeBrowsers = Read-Host "Deseja fechar os navegadores para garantir a restauração de Downloads? (S/N)"
    if ($closeBrowsers -match "S|s") {
        Stop-Process -Name $browsers -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }
}

foreach ($folder in $foldersToRestore) {
    $regName = $folder.RegName
    $defaultName = $folder.DefaultName
    
    # Caminho Padrão Esperado (Destino da Restauração)
    # Geralmente é C:\Users\Nome\Pasta
    # Nota: Usamos o nome padrão em inglês para a estrutura física, o Windows localiza visualmente via desktop.ini
    $targetPath = "$userProfilePath\$defaultName"

    # Caminho Atual (Onde os arquivos estão AGORA - ex: D:\Users\Nome\Documents)
    try {
        $currentRegistryPath = Get-ItemProperty -Path $userProfileConfig -Name $regName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $regName
        if ($null -ne $currentRegistryPath) {
             $currentRegistryPath = [System.Environment]::ExpandEnvironmentVariables($currentRegistryPath)
        }
    } catch { 
        $currentRegistryPath = $null 
    }

    Write-Host "" 
    Write-Host "Processando: $defaultName" -ForegroundColor Cyan

    # Se não temos registro atual, assumimos que já está padrão ou quebrado, mas ainda verificamos se existe Junction em C:
    
    # 1. Remover Junction no local padrão (C:) se existir
    $item = Get-Item -Path $targetPath -ErrorAction SilentlyContinue
    if ($item -and ($item.Attributes -match "ReparsePoint")) {
        Write-Host "  -> Removendo Junction (Atalho) em $targetPath..."
        Remove-Item -Path $targetPath -Force -ErrorAction Stop
    } elseif ($item -and ($item.Attributes -match "Directory")) {
        # Se existe uma pasta real em C:, verifique se NÃO é a mesma que está no registro
        # Se $currentRegistryPath for diferente de $targetPath, então temos arquivos em dois lugares?
        # Simplesmente garantimos que não sobrescrevemos sem querer, ou mesclamos.
    }

    # 2. Mover arquivos DE VOLTA (Do disco D: para C:)
    # Só movemos se o registro apontava para fora E o caminho "de fora" existe
    if ($currentRegistryPath -and ($currentRegistryPath -ne $targetPath) -and (Test-Path $currentRegistryPath)) {
        Write-Host "  -> Movendo arquivos de $currentRegistryPath para $targetPath..."
        
        # Garante que destino existe
        if (-not (Test-Path $targetPath)) {
            New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
        }

        # Robocopy Move
        $roboParams = @("$currentRegistryPath", "$targetPath", "/E", "/MOVE", "/COPY:DAT", "/R:1", "/W:1", "/XJ", "/NP", "/NFL", "/NDL", "/NJH", "/NJS")
        $roboResult = & robocopy @roboParams
        
        # O código 1 é sucesso (arquivos copiados), 0 é nada a fazer. >=8 é erro grave.
        if ($LASTEXITCODE -ge 8) {
             Write-Error "  -> Erro ao mover arquivos de volta. Verifique manualmente."
        } else {
             Write-Host "  -> Arquivos movidos com sucesso." -ForegroundColor Green
             # Tenta remover a pasta vazia de origem se sobrou
             Remove-Item -Path $currentRegistryPath -Force -ErrorAction SilentlyContinue
        }
    } else {
        Write-Host "  -> Nada para mover (já parece estar no local original ou registro não encontrado)." -ForegroundColor Gray
    }

    # 3. Restaurar Registro
    Write-Host "  -> Restaurando chave de registro para o padrão (%USERPROFILE%..."
    # Valor padrão geralmente é %USERPROFILE%\Downloads, etc.
    # Exceção: Personal -> %USERPROFILE%\Documents
    $defaultRegValue = "%USERPROFILE%\$defaultName"
    
    # Ajuste fino para chaves legadas ou nomes específicos se necessário, mas o padrão %USERPROFILE%\Nome costuma funcionar.
    
    Set-ItemProperty -Path $userProfileConfig -Name $regName -Value $defaultRegValue -Type ExpandString
    Write-Host "  -> Registro atualizado."
}

Write-Host ""
Write-Host "=========================================="
Write-Host "   Restauração Concluída"
Write-Host "=========================================="
Write-Host "Reinicie o Explorer (ou o computador) para garantir que tudo volte ao normal."
Pause

Stop-Process -Name explorer -Force
Start-Sleep -Seconds 2
if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) {
    Start-Process explorer
}
