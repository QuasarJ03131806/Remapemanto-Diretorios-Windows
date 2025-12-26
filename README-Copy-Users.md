# Documentação: Script de Cópia de Usuários

**Arquivo:** `Copy-WindowsUsers.ps1`

## O que este script faz?
Este script é uma ferramenta de **Migração de Dados**.
Ele serve para quando você acabou de formatar o computador (tem um disco `C:` limpo) e precisa copiar as pastas de usuários (Documentos, Imagens, Desktop, etc.) de um HD antigo ou externo conectado via USB.

### Funcionalidades:
- Copia recursivamente a pasta `Users` inteira.
- Mantém as datas originais dos arquivos.
- Ignora arquivos de sistema que não podem ser copiados.
- Pede permissão de Administrador automaticamente.

---

## Como usar (Via Interface Gráfica)
1. Conecte o HD externo contendo o backup.
2. Clique com o botão direito no arquivo `Copy-WindowsUsers.ps1`.
3. Escolha a opção **"Executar com o PowerShell"**.
4. Siga as instruções na janela azul que abrir (digite a letra da unidade de origem).

---

## Como usar (Via Terminal / Linha de Comando)
Se preferir usar o terminal, abra o **PowerShell como Administrador** e digite:

```powershell
# 1. Navegue até a pasta onde salvou o script
cd "C:\Caminho\Onde\Salvou"

# 2. Permita a execução de scripts (caso dê erro de segurança)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# 3. Execute o script
.\Copy-WindowsUsers.ps1
```
