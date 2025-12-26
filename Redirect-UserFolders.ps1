<#
.SYNOPSIS
    Move pastas do usuário (Documentos, Desktop, etc.) para uma unidade secundária e atualiza o Registro.
    Cria junções (Junctions) para manter compatibilidade transparente.

.DESCRIPTION
    Este script redireciona as pastas de perfil do usuário atual para um disco maior.
    Ele altera a chave 'User Shell Folders' no Registro e move os arquivos existentes.

.NOTES
    Autor: Mizael Souto
    Empresa: Uppertec
    Data: 2025-12-22
    AVISO: Modifica o Registro do Windows (HKCU).
#>

# 1. Garante execução como Administrador
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Solicitando permissão de Administrador para realizar mudanças no sistema..." -ForegroundColor Yellow
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

Clear-Host
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   REDIRECIONAMENTO DE PASTAS DE USUÁRIO" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Este script moverá suas pastas (Documentos, Desktop, etc.) para outro disco."
Write-Host "Isso ajuda a liberar espaço no drive C: (SSD)."
Write-Host ""

# 2. Configurações e Segurança
# 2.1 Cria Ponto de Restauração (Segurança)
try {
    Write-Host "Criando Ponto de Restauração do Sistema (MAPEAMENTO_DE_DIRETORIO)..." -ForegroundColor Yellow
    Checkpoint-Computer -Description "MAPEAMENTO_DE_DIRETORIO" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
    Write-Host "Ponto de restauração criado com sucesso." -ForegroundColor Green
} catch {
    Write-Warning "Não foi possível criar o Ponto de Restauração. Verifique se a Proteção do Sistema está ativada."
    Write-Warning "Erro: $_"
    Write-Host "Continuando com o script em 5 segundos..."
    Start-Sleep -Seconds 5
}

# 2.2 Backup do Registro (.reg)
# Exporta a chave original para um arquivo .reg, permitindo restauração manual fácil.
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFile = "$((Get-Location).Path)\UserShellFolders_Backup_$timestamp.reg"
try {
    Write-Host "Criando Backup do Registro (.reg)..." -ForegroundColor Yellow
    $regKey = "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
    # Usa cmd /c reg export para garantir compatibilidade
    cmd /c "reg export `"$regKey`" `"$backupFile`" /y" | Out-Null
    
    if (Test-Path $backupFile) {
        Write-Host "Backup do registro salvo em:" -ForegroundColor Green
        Write-Host "  -> $backupFile" -ForegroundColor Gray
    } else {
        Write-Warning "O arquivo de backup do registro não foi criado."
    }
} catch {
    Write-Warning "Erro ao exportar registro: $_"
}

# 2.3 Detecção de Sistema e Idioma
$os = Get-CimInstance Win32_OperatingSystem
$build = $os.BuildNumber
$osName = "Windows 10"
if ($build -ge 22000) { $osName = "Windows 11" }

$culture = Get-UICulture
$lang = $culture.Name

Write-Host "Sistema Detectado: $osName (Build $build)" -ForegroundColor Gray
Write-Host "Idioma do Sistema: $lang" -ForegroundColor Gray
Write-Host ""

# 3. Configurações Iniciais
$currentUser = $env:USERNAME
$userProfileConfig = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"

# Lista de pastas conhecidas para redirecionar (apenas nomes de chave de registro)
# O nome da pasta de destino será descoberto dinamicamente para preservar o idioma (ex: Documentos vs Documents)
$foldersToMove = @(
    @{ RegName="Desktop";                                      DefaultName="Desktop" },
    @{ RegName="Personal";                                     DefaultName="Documents" },
    @{ RegName="{374DE290-BC0F-4445-838C-AB42E860FE27}";       DefaultName="Downloads" },
    @{ RegName="My Music";                                     DefaultName="Music" },
    @{ RegName="My Pictures";                                  DefaultName="Pictures" },
    @{ RegName="My Video";                                     DefaultName="Videos" }
)

# 4. Solicita Unidade de Destino
$targetDrive = Read-Host "Digite a LETRA da unidade SECUNDÁRIA (ex: D, E) onde os arquivos ficarão"
$targetDrive = $targetDrive -replace ":|\\|/", ""

if ([string]::IsNullOrWhiteSpace($targetDrive)) {
    Write-Error "Nenhuma unidade válida informada."
    Pause
    Exit
}

$targetRoot = "${targetDrive}:\Users\$currentUser"

Write-Host ""
Write-Host "Os arquivos serão movidos de C:\Users\$currentUser para $targetRoot" -ForegroundColor Yellow
$confirm = Read-Host "Deseja continuar? (S/N)"
if ($confirm -notmatch "S|s") { Exit }

# Cria diretório base se não existir
if (-not (Test-Path $targetRoot)) {
    New-Item -ItemType Directory -Path $targetRoot -Force | Out-Null
}


# 4.1 Verificação de Arquivos em Uso (Navegadores)
# Navegadores costumam travar a pasta Downloads. Oferecemos para fechar.
$browsers = @("chrome", "msedge", "firefox", "opera", "brave")
$runningBrowsers = Get-Process -Name $browsers -ErrorAction SilentlyContinue

if ($runningBrowsers) {
    Write-Host ""
    Write-Host "ATENÇÃO: Navegadores detectados em execução!" -ForegroundColor Red
    Write-Host "Para mover a pasta Downloads com sucesso, é necessário fechar os navegadores." -ForegroundColor Yellow
    Write-Host "Navegadores encontrados: $(($runningBrowsers.ProcessName | Select-Object -Unique) -join ', ')"
    
    $closeBrowsers = Read-Host "Deseja fechar os navegadores automaticamente agora? (S/N)"
    if ($closeBrowsers -match "S|s") {
        Write-Host "Fechando navegadores..." -ForegroundColor Yellow
        Stop-Process -Name $browsers -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        Write-Host "Navegadores fechados." -ForegroundColor Green
    } else {
        Write-Warning "Os navegadores permaneceram abertos. ERRO ESPERADO: A pasta Downloads pode falhar ao mover."
    }
}

# 5. Loop de Processamento
foreach ($folder in $foldersToMove) {
    $regName = $folder.RegName
    $defaultName = $folder.DefaultName
    
    # Caminho Atual (lê do registro)
    # Caminho Atual (lê do registro)
    try {
        $currentPath = Get-ItemProperty -Path $userProfileConfig -Name $regName -ErrorAction Stop | Select-Object -ExpandProperty $regName
        # Expande variáveis de ambiente se houver (ex: %USERPROFILE%)
        $currentPath = [System.Environment]::ExpandEnvironmentVariables($currentPath)
    }
    catch {
        # FALHA DE LEITURA (Provavelmente a chave não existe, comum para Downloads em instalações padrão)
        if ($defaultName -eq "Downloads") {
            Write-Warning "A chave de registro para Downloads não foi encontrada (Padrão do Windows)."
            Write-Host "  -> Tentando assumir o local padrão: $env:USERPROFILE\Downloads" -ForegroundColor Gray
            $currentPath = "$env:USERPROFILE\Downloads"
            
            if (-not (Test-Path $currentPath)) {
                 Write-Error "  -> O caminho padrão não existe. Pulando..."
                 continue
            }
        } else {
            Write-Warning "Não foi possível ler a localização de ($defaultName). Pulando..."
            continue
        }
    }

    # DIAGNÓSTICO DE CAMINHO
    Write-Host "  -> Origem Detectada: $currentPath" -ForegroundColor DarkGray
    if ($currentPath -match "OneDrive") {
        Write-Warning "  -> ATENÇÃO: Esta pasta parece estar sendo gerenciada pelo OneDrive! Isso pode causar erros de cópia."
    }

    # Descobre o nome da pasta atual (preserva idioma)
    # Se o caminho for C:\Users\Mizael\Documentos, o nome será "Documentos"
    $folderLeafName = Split-Path $currentPath -Leaf
    if ([string]::IsNullOrWhiteSpace($folderLeafName)) {
        $folderLeafName = $defaultName
    }

    Write-Host "" 
    Write-Host "Processando: $folderLeafName..." -ForegroundColor Green

    # Caminho Novo: Usa o MESMO nome da pasta original
    $newPath = "$targetRoot\$folderLeafName"

    # Se já estiver no destino, pula
    if ($currentPath -eq $newPath) {
        Write-Host "  -> Já está redirecionado. Pulando." -ForegroundColor Gray
        continue
    }

    # A. Cria nova pasta e VALIDA
    if (-not (Test-Path $newPath)) {
        try {
            New-Item -ItemType Directory -Path $newPath -Force -ErrorAction Stop | Out-Null
            Write-Host "  -> Pasta criada no destino: $newPath"
        } catch {
            Write-Error "  -> ERRO CRÍTICO: Não foi possível criar a pasta no destino ($newPath)."
            Write-Error "  -> Motivo: $_"
            Write-Warning "  -> Pulando $folderLeafName para evitar danos."
            continue # Pula para a próxima pasta
        }
    }

    # Re-valida existência (dupla checagem)
    if (-not (Test-Path $newPath)) {
        Write-Error "  -> ERRO: A pasta de destino não existe após tentativa de criação."
        continue
    }

    # B. Copia arquivos (Robocopy /COPY)
    Write-Host "  -> Copiando arquivos (Robocopy)..."
    
    # /E :: copia subpastas
    # /COPY:DAT :: dados, atributos, data
    # /R:1 /W:1 :: tenta 1 vez esperar 1s se falhar
    $roboParams = @("$currentPath", "$newPath", "/E", "/COPY:DAT", "/R:1", "/W:1", "/XJ", "/NP", "/NFL", "/NDL", "/NJH", "/NJS")
    $roboResult = & robocopy @roboParams
    
    # Verifica Código de Saída do Robocopy (0-7 = Sucesso, >=8 = Falha)
    $exitCode = $LASTEXITCODE
    if ($exitCode -ge 8) {
        Write-Error "  -> ERRO NO ROBOCOPY (Código $exitCode). A cópia falhou ou foi incompleta."
        Write-Warning "  -> O registro NÃO será alterado para esta pasta."
        continue
    } else {
        Write-Host "  -> Cópia concluída com sucesso (Código $exitCode)." -ForegroundColor Green
    }

    # C. Atualiza Registro (SOMENTE SE A CÓPIA FOI SUCESSO)
    Write-Host "  -> Atualizando Registro..."
    Set-ItemProperty -Path $userProfileConfig -Name $regName -Value $newPath

    # D. Limpeza e Junction
    # Só limpamos se o registro foi atualizado (segurança)
    if (Test-Path $currentPath) {
        Write-Host "  -> Tentando remover pasta antiga para criar Junction..."
        Remove-Item -Path $currentPath -Recurse -Force -ErrorAction SilentlyContinue
    }

    if (-not (Test-Path $currentPath)) {
        cmd /c mklink /J "$currentPath" "$newPath" | Out-Null
        Write-Host "  -> Junction criado em $currentPath"
    } else {
        # Falha ao apagar (arquivos em uso)
        Write-Warning "  -> [AVISO] Não foi possível remover completamente a pasta antiga (arquivos em uso?)."
        Write-Warning "  -> A MIGRAÇÃO FOI UM SUCESSO! O Registro aponta para o novo local."
        Write-Warning "  -> A pasta antiga pode ser apagada manualmente após reiniciar."
    }
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   ATUALIZAÇÃO DE SISTEMA" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Para que todas as alterações tenham efeito, o Explorer precisa ser reiniciado."
Write-Host "Sua barra de tarefas irá sumir por um instante."
Write-Host ""
Pause

# 6. Reinicia Explorer
Stop-Process -Name explorer -Force
Start-Sleep -Seconds 2
# O Explorer geralmente reinicia sozinho no Windows 10/11. Se não, iniciamos.
if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) {
    Start-Process explorer
}

Write-Host ""
Write-Host "Concluído! Verifique se suas pastas agora abrem no novo local." -ForegroundColor Green
Pause
