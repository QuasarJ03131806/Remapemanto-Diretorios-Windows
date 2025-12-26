# Documentação: Restauração de Pastas de Usuário

**Arquivo:** `Restore-UserFolders.ps1`

## O que este script faz?
Este script serve para **desfazer** as alterações feitas pelo script de redirecionamento (`Redirect-UserFolders.ps1`). Ele é útil se você quiser voltar suas pastas (Documentos, Downloads, etc.) para o disco C: (local original do Windows).

### Funcionalidades:
1.  **Move os Arquivos de Volta**: Pega seus arquivos do disco secundário (ex: D:) e move de volta para o disco C:.
2.  **Remove Atalhos (Junctions)**: Apaga os atalhos que foram criados no lugar das pastas originais.
3.  **Restaura o Registro**: Configura o Windows para considerar o disco C: como o local padrão novamente.

---

## Pré-requisitos
> [!IMPORTANT]
> **Espaço em Disco**: Antes de rodar, verifique se o seu disco C: tem espaço livre suficiente para receber todos os seus arquivos de volta!

## Como usar

### Opção 1: Via Clique Direito
1. Clique com o botão direito no arquivo `Restore-UserFolders.ps1`.
2. Escolha **"Executar com o PowerShell"**.
3. Confirme as solicitações (digite `S` e Enter quando pedido).

### Opção 2: Via Terminal (PowerShell)
1. Abra o PowerShell como Administrador.
2. Navegue até a pasta do script.
3. Execute:
   ```powershell
   .\Restore-UserFolders.ps1
   ```

## O que acontece durante a execução?
- O script pode pedir para fechar navegadores (Chrome, Edge, etc) se estiver restaurando a pasta **Downloads**.
- Ele mostrará o progresso de movimentação dos arquivos.
- Ao final, ele reiniciará o Windows Explorer para aplicar as mudanças.
