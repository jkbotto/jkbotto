# Prompt — versão enxuta de skills do Claude Code

> Cole todo o conteúdo abaixo da linha numa sessão do Claude Code.
> Funciona em Windows, macOS e Linux — o Claude adapta os comandos.

---

Instale um conjunto curado de skills no meu Claude Code, no escopo de usuário. Execute
tudo sem me pedir confirmação a cada passo e me dê um relatório final. Se algum passo
falhar, siga com os demais e reporte a falha no fim.

## Parte 0 — Limpeza (execute SOMENTE se eu já tiver a versão inchada instalada)

Rode `claude plugin list` primeiro. Se aparecer `ecc`, `document-skills` ou `claude-api`,
remova-os — o `ecc` traz 278 skills e 20 hooks que disparam a cada chamada de ferramenta,
e os outros dois duplicam skills que o app já fornece nativamente:

```
claude plugin uninstall ecc@ecc
claude plugin uninstall document-skills@anthropic-agent-skills
claude plugin uninstall claude-api@anthropic-agent-skills
```

Depois, em `~/.claude/skills`, **apague todas as pastas EXCETO** estas seis:
`eval-driven-dev`, `humanizer`, `react-best-practices`, `screenshot`,
`security-best-practices`, `security-threat-model`.

Se a pasta `~/.claude/skills` não existir ou já estiver enxuta, pule esta parte.

## Parte 1 — Plugins do núcleo

```
claude plugin marketplace add anthropics/skills
claude plugin marketplace add jarrodwatts/claude-hud
claude plugin marketplace add ayghri/i-have-adhd

claude plugin install example-skills@anthropic-agent-skills
claude plugin install claude-hud@claude-hud
claude plugin install i-have-adhd@i-have-adhd
```

## Parte 2 — Skills avulsas do núcleo

Clone os repositórios num diretório temporário com `--depth 1` e copie as pastas
indicadas para `~/.claude/skills/` (crie a pasta se não existir):

1. `https://github.com/github/awesome-copilot` → copiar `skills/eval-driven-dev`
   (use sparse checkout: o repositório é grande)
2. `https://github.com/openai/skills` → copiar **apenas estas três** de
   `skills/.curated/`: `security-best-practices`, `security-threat-model`, `screenshot`
3. `https://github.com/blader/humanizer` → **atenção:** este repositório tem o `SKILL.md`
   na raiz e o manifesto dele é rejeitado pelo `claude plugin install` (chave `$schema`
   inválida). Crie `~/.claude/skills/humanizer/` e copie o `SKILL.md` da raiz do repo
   para lá.

## Parte 3 — Opcionais (instale apenas se a condição se aplicar a mim; me pergunte se não souber)

- **Só se eu programo de fato, com repositório git e suíte de testes:**
  ```
  claude plugin marketplace add obra/superpowers-marketplace
  claude plugin install superpowers@superpowers-marketplace
  ```
- **Só se eu construo interfaces / front-end:**
  ```
  claude plugin marketplace add nextlevelbuilder/ui-ux-pro-max-skill
  claude plugin marketplace add pbakaus/impeccable
  claude plugin install ui-ux-pro-max@ui-ux-pro-max-skill
  claude plugin install impeccable@impeccable
  ```
- **Só se eu uso React ou Next.js:** clonar `https://github.com/vercel-labs/agent-skills`
  e copiar `skills/react-best-practices` para `~/.claude/skills/`.

## Parte 4 — Verificação e limpeza

- Confirme que cada pasta em `~/.claude/skills` contém um `SKILL.md`.
- Rode `claude plugin list` e mostre o resultado.
- Apague o diretório temporário dos clones.
- Me lembre de: (a) reiniciar o Claude Code, e (b) rodar `/claude-hud:setup` numa sessão
  interativa para configurar a barra de status.

## Regra importante

**Não instale nada além do que está listado aqui.** Se você encontrar outros
repositórios de skills interessantes durante o processo, apenas mencione no relatório
final — não instale. Volume de skills é custo: cada descrição carregada compete por
ativação e infla o contexto de toda sessão.

---

## Pré-requisitos

- Claude Code v2.x ou superior (o subcomando `claude plugin` existe a partir dessa versão)
- `git` instalado
- No Windows, o `i-have-adhd` executa um hook `sh` — precisa de Git Bash no PATH
  (normalmente já vem junto com o Git)
