FROM biggates/esp-idf-devcontainer:idf_v5.4.2_qemu_20250228

ENV DEBIAN_FRONTEND=noninteractive
ENV SHELL=/usr/bin/zsh

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        sudo \
        xz-utils \
        zsh \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs \
    && npm uninstall -g @openai/codex 2>/dev/null; npm install -g npm@latest opencode-ai \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git /root/.oh-my-zsh \
    && printf 'export ZSH="/root/.oh-my-zsh"\nZSH_THEME="jonathan"\nplugins=(git)\nsource "$ZSH/oh-my-zsh.sh"\nexport PATH="/usr/local/bin:$PATH"\n' > /root/.zshrc \
    && chsh -s /usr/bin/zsh root
