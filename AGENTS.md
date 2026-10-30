# Instruções para o Codex

Leia `README.md` e `MANIFESTO.md` antes de trabalhar. Respeite as decisões arquiteturais do manifesto; não escolha nem substitua componentes importantes sem aprovação.

## Implementação

- Priorize simplicidade, configuração nativa e manutenção fácil. Não introduza frameworks, CI, workflows, infraestrutura permanente de testes ou abstrações desnecessárias.
- Use Eww para interfaces personalizadas do desktop e ferramentas especializadas para suas funções. Prefira integrações por interfaces e comandos nativos a código próprio.
- Mantenha configurações de usuário em `~/.config/`, recursos estáticos em `~/.local/share/` e scripts próprios do desktop exclusivamente em `~/.scripts/`. Esses scripts devem ser Bash, simples, independentes e de responsabilidade única; os scripts do instalador permanecem em `src/`.
- Priorize pacotes oficiais do Arch e projetos ativos e confiáveis. Considere o AUR apenas excepcionalmente, após avaliar procedência, manutenção e `PKGBUILD`.
- Instale e atualize dependências por gerenciamento de pacotes. Não faça compilações ou instalações manuais, nem mantenha forks, pacotes customizados, modificações em código-fonte de terceiros ou patches próprios.

## Desenvolvimento e reprodução

- Em tarefas de experimentação, configure e valide no ambiente de teste sem modificar o repositório, salvo autorização específica.
- Registre pacotes, serviços, alterações persistentes e eventuais limitações em `~/.config/NOTES.md` durante a experimentação. Esse registro não é um arquivo de configuração a ser reproduzido no desktop final.
- Assuma os testes técnicos das alterações aprovadas: verifique funcionamento real, integrações e regressões pelos meios disponíveis. Diferencie testes diretos de verificações indiretas; não declare validado o que não foi observado. Evite pedir testes manuais rotineiros ao operador.
- Quando solicitado a consolidar o ambiente, incorpore somente configurações, scripts e recursos aprovados e adapte o instalador para reproduzir pacotes, serviços e ajustes do sistema em uma instalação limpa.
- Não versione credenciais, chaves privadas, caches, artefatos de compilação ou dados temporários.

## Segurança e colaboração

- Peça aprovação antes de operações destrutivas, mudanças sensíveis ou decisões arquiteturais fora do escopo autorizado.
- Informe decisões relevantes, limitações, testes realizados e mudanças persistentes.
- Não crie commits sem solicitação explícita.
