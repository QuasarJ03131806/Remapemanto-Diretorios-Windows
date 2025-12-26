O script tem como objetivo remapear as pastas do Windows 10 ou 11 (Documentos, Área de Trabalho, Downloads, Imagens, Vídeos e Músicas), independentemente do idioma, apontando-as para uma unidade secundária. Isso é extremamente útil para quem possui um SSD pequeno (128 GB ou 250 GB) como unidade C:, dedicada apenas ao sistema operacional e programas. Ao definir uma unidade secundária (como a letra E:), o armazenamento de arquivos torna-se automático. A grande vantagem é eliminar a necessidade de copiar ou mover arquivos manualmente, otimizando a organização e o desempenho do sistema.



Guia de Scripts de Gerenciamento de Usuários
Abaixo estão as descrições detalhadas de cada script e suas respectivas funcionalidades.

1. Redirect-UserFolders

Este script redireciona os diretórios do usuário da unidade C: para outra unidade de destino (identificada por uma LETRA específica). Uma vez configurado, todo o conteúdo novo será armazenado automaticamente nesta nova unidade.

Segurança: Devido às alterações profundas no sistema, o script gera automaticamente um Ponto de Restauração e um arquivo de backup. Confirme se o ponto de restauração foi criado com sucesso antes de avançar.

Restrição de Localização: O script não deve ser executado a partir de pastas do usuário ou diretórios que serão redirecionados. Ele deve estar localizado na raiz do Drive C: ou em um pendrive.

2. Restore-UserFolders

Este script é utilizado para reverter o processo. Ele tenta desfazer as modificações realizadas no Registro do Windows, buscando restaurar os caminhos padrão das pastas do sistema.

3. Copy-WindowsUser

Script voltado para cenários de manutenção e formatação. Ele facilita a migração ao copiar os arquivos do usuário de uma instalação antiga para uma nova instalação de forma organizada.

⚠️ Termo de Responsabilidade e Isenção de Danos

O uso destes scripts é de total e exclusiva responsabilidade do usuário.

Isenção de Garantia: O desenvolvedor não fornece garantias de qualquer tipo quanto ao funcionamento ou compatibilidade absoluta com todas as versões do Windows.

Limitação de Responsabilidade: O desenvolvedor não se responsabiliza por:

Erros de execução causados por mau uso.

Perda total ou parcial de arquivos e dados pessoais.

Falhas no sistema operacional, instabilidades ou telas azuis (BSOD).

Quaisquer danos diretos ou indiretos resultantes do uso destas ferramentas.

Recomenda-se fortemente possuir um backup físico e externo dos seus dados importantes antes de executar qualquer script que altere o Registro ou mova diretórios do sistema.

Instruções Adicionais

Cada script acompanha um arquivo Readme específico. Leia as instruções contidas neles para saber os comandos exatos de execução.
