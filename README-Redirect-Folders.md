# Documentação: Script de Redirecionamento de Pastas

**Arquivo:** `Redirect-UserFolders.ps1`

## O que este script faz?
Este script é uma ferramenta de **Otimização de Armazenamento**.
Ele serve para computadores que têm dois discos:
1. **Disco C: (SSD Rápido, mas pequeno)**: Para o Windows e programas.
2. **Disco D:/E: (HD Grande)**: Para arquivos pesados.

O script move suas pastas pessoais (Downloads, Documentos, Área de Trabalho, Vídeos) para o disco grande e configura o Windows para usar esse novo local automaticamente.

### Funcionalidades:
- **Detecção Inteligente**: Identifica automaticamente se é Windows 10 ou 11 e o idioma do sistema.
- **Preservação de Idioma**: Mantém o nome original da pasta (ex: move "Documentos" como "Documentos", não "Documents").
- Move os arquivos existentes para o novo disco mantendo atributos e datas.
- Atualiza o Registro do Windows (User Shell Folders).
- Cria atalhos de compatibilidade (Junctions) no local antigo.
- Reinicia o Windows Explorer para aplicar as mudanças.

---

## Como usar (Via Interface Gráfica)
> **Atenção:** Execute este script logado no usuário que você deseja mover.

1. Clique com o botão direito no arquivo `Redirect-UserFolders.ps1`.
2. Escolha a opção **"Executar com o PowerShell"**.
3. Siga as instruções (digite a letra da unidade de destino, ex: `D`).

---

## Como usar (Via Terminal / Linha de Comando)
Se preferir usar o terminal, abra o **PowerShell** (não precisa ser Admin inicialmente, o script pedirá se necessário, mas é bom estar no seu usuário):

```powershell
# 1. Navegue até a pasta onde salvou o script
cd "C:\Caminho\Onde\Salvou"

# 2. Permita a execução de scripts
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# 3. Execute o script
.\Redirect-UserFolders.ps1
```
