# Manifesto

## Visão

Construir um desktop Arch Linux pessoal, mínimo, duradouro e profundamente personalizável, com controle claro sobre sua aparência e seu comportamento. A complexidade deve estar nas configurações explícitas, não em uma infraestrutura própria difícil de manter.

## Princípios

- **Minimalismo pragmático:** utilizar apenas componentes que tragam benefícios concretos, sem um desktop environment completo, frameworks ou abstrações desnecessárias.
- **Responsabilidades bem definidas:** cada ferramenta executa sua função nativa. A interface apresenta informações e aciona operações; não reimplementa gerenciamento de janelas, áudio, rede ou serviços do sistema.
- **Interface visual consistente:** utilizar o Eww como base das interfaces personalizadas do desktop - barra, central de aplicativos, menus, painéis e widgets. Não substituir por Eww interfaces especializadas, aplicativos ou componentes com requisitos próprios de segurança apenas por uniformidade estética.
- **Configuração antes de programação:** privilegiar opções declarativas, mecanismos nativos, IPC e comandos existentes. Admitir somente integrações próprias pequenas, independentes e justificadas, escritas em Bash.
- **Organização previsível:** concentrar configurações de usuário em `~/.config/`, scripts próprios do desktop em `~/.scripts/` e recursos estáticos de usuário em `~/.local/share/`. Evitar lógica e arquivos espalhados por locais arbitrários.
- **Temas sem framework próprio:** manter cores, fontes e estilos consistentes e centralizados onde cada ferramenta permitir. Respeitar os formatos nativos dos aplicativos, sem impor um sistema universal de geração de configurações.
- **Dependências sustentáveis:** priorizar pacotes dos repositórios oficiais do Arch Linux e projetos consolidados e ativos. Aceitar AUR somente como exceção avaliada. Utilizar gerenciamento de pacotes, sem instalações manuais, forks, alterações em código-fonte de terceiros ou patches próprios.
- **Reprodutibilidade:** o instalador deve provisionar pacotes, serviços, permissões e demais ajustes do sistema, além de disponibilizar as configurações e scripts necessários. Uma instalação limpa deve reconstruir o ambiente sem intervenções manuais não documentadas.

## Decisões fundamentais

- **Arch Linux:** base rolling release, escolhida por controle, transparência e flexibilidade.
- **Wayland e Sway:** composição e gerenciamento de janelas com suporte a tiling e floating.
- **Eww:** tecnologia central das interfaces visuais personalizadas, separada dos serviços e aplicativos que elas controlam.
- **Ferramentas especializadas:** terminal, gerenciador de arquivos em terminal, notificações e demais funcionalidades continuam sob responsabilidade de programas próprios, configuráveis e independentes.
- **Instalador em Shell:** processo de instalação direto, legível e modular, responsável por reconstruir o sistema a partir do repositório.

O objetivo não é reduzir a quantidade de ferramentas a qualquer custo: é reduzir a complexidade que precisamos desenvolver, entender e manter.
