# Instruções para o Codex

Leia `README.md` e `MANIFESTO.md` antes de trabalhar neste projeto. O manifesto é a referência para os objetivos e as decisões arquiteturais.

## Princípios de trabalho

- Priorize simplicidade, configuração nativa e facilidade de manutenção.
- Não introduza frameworks, CI, workflows, infraestrutura de testes ou abstrações desnecessárias.
- Não escolha componentes arquiteturais importantes sem aprovação.
- Prefira ferramentas existentes a código próprio. Quando necessários, scripts de integração devem ser simples, independentes, escritos exclusivamente em Bash e centralizados em `~/.scripts/`.
- Priorize os repositórios oficiais do Arch Linux e projetos consolidados, ativos e bem mantidos. Utilize o AUR apenas excepcionalmente, após avaliar a procedência, a manutenção e o `PKGBUILD`.
- Instale e atualize dependências por gerenciamento de pacotes. Não realize compilações ou instalações manuais, nem mantenha forks, patches próprios ou modificações no código-fonte de terceiros.

## Desenvolvimento e reprodução

- Durante a experimentação, configure o Arch Linux diretamente na VM, sem modificar o repositório.
- Registre pacotes instalados, serviços habilitados e alterações persistentes em `~/.config/NOTES.md`.
- Quando solicitado, incorpore ao repositório apenas as configurações aprovadas e adapte o instalador para reproduzi-las em uma instalação limpa.
- Não versione credenciais, chaves privadas, caches ou dados temporários.

## Segurança e colaboração

- Solicite aprovação antes de operações destrutivas ou alterações sensíveis no sistema.
- Comunique decisões relevantes, limitações e mudanças realizadas.
- Não crie commits sem solicitação explícita.