# Objetivo

Construir um desktop Arch Linux mínimo, modular e duradouro, com controle total sobre aparência e comportamento. Usar apenas os componentes necessários, priorizando ferramentas especializadas, altamente configuráveis e de responsabilidades bem definidas. Centralizar configurações compartilhadas e garantir facilidade de manutenção e reprodução. Configuração extensa é aceitável; desenvolver e manter código estrutural próprio, não.

# Decisões

- **Arch Linux:** base do sistema, pela simplicidade, flexibilidade e controle.
- **Sem desktop environment:** compor o ambiente apenas com os componentes necessários.
- **Window manager híbrido:** suportar tiling e floating.
- **Componentes independentes:** window manager, barra, launcher, gerenciador de arquivos e tela de login, cada um com sua responsabilidade.
- **Gerenciador de arquivos no terminal:** priorizar uma interface TUI.
- **Interface altamente customizável:** suportar estilos, hover, menus, widgets e interações personalizadas.
- **Configuração centralizada:** compartilhar cores, fontes, espaçamentos e demais valores globais sempre que possível.
- **Configuração acima de programação:** preferir funcionalidades nativas e configuração declarativa. Permitir helpers pontuais, evitando código estrutural próprio.
- **Minimalismo pragmático:** evitar dependências, abstrações e complexidade sem benefício concreto.
- **Instalador simples:** manter scripts Shell e poucos arquivos, sem CI, workflows ou infraestrutura de testes.
- **Desenvolvimento na VM:** instalar primeiro um Arch Linux mínimo e configurar o desktop diretamente na VM, utilizando o Codex via SSH.
- **Reprodutibilidade:** após validar o desktop, incorporar ao repositório os arquivos de configuração, os pacotes e as alterações de sistema necessárias para reproduzi-lo em uma instalação limpa.
- **Decisões progressivas:** selecionar componentes conforme as necessidades reais, sem antecipar escolhas ou congelar ferramentas prematuramente.
