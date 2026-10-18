# Rollback da otimizacao de skills

Executado em 2026-07-29. Tudo abaixo e reversivel com estes comandos.

## Plugins removidos

```bash
claude plugin install ecc@ecc
claude plugin install document-skills@anthropic-agent-skills
claude plugin install claude-api@anthropic-agent-skills
```

Os marketplaces continuam registrados, entao o install acima funciona direto.

### Se quiser o ECC de volta SEM os 20 hooks

O ECC instala 20 hooks que disparam em praticamente toda chamada de ferramenta
(incluindo o GateGuard, que bloqueia a primeira escrita em cada arquivo).
Para reinstalar so as skills, defina antes de abrir o Claude Code:

```
ECC_GATEGUARD=off
ECC_DISABLED_HOOKS=pre:observe:continuous-learning,post:dispatcher:sync,post:dispatcher:async,stop:desktop-notify,stop:format-typecheck,stop:check-console-log
```

## Plugins mantidos

superpowers@superpowers-marketplace, example-skills@anthropic-agent-skills,
ui-ux-pro-max@ui-ux-pro-max-skill, impeccable@impeccable

## Skills avulsas mantidas (5)

eval-driven-dev, react-best-practices, security-best-practices,
security-threat-model, screenshot

## Skills avulsas removidas (38)

Para restaurar todas de uma vez, repita a Parte 2 do arquivo
PROMPT-INSTALAR-SKILLS.md. Origem de cada uma:

- openai/skills (`skills/.curated/`): aspnet-core, chatgpt-apps, cli-creator,
  cloudflare-deploy, define-goal, figma, figma-code-connect-components,
  figma-create-design-system-rules, figma-create-new-file, figma-generate-design,
  figma-generate-library, figma-implement-design, figma-use, gh-address-comments,
  gh-fix-ci, hatch-pet, jupyter-notebook, linear, migrate-to-codex, netlify-deploy,
  notion-knowledge-capture, notion-meeting-intelligence, notion-research-documentation,
  notion-spec-to-implementation, openai-docs, pdf, playwright, playwright-interactive,
  render-deploy, security-ownership-map, sentry, speech, transcribe, vercel-deploy,
  winui-app, yeet
- ComposioHQ/awesome-claude-skills: connect-apps
- K-Dense-AI/scientific-agent-skills: docx

## Instalado DEPOIS da limpeza (2026-07-29)

```bash
claude plugin install claude-hud@claude-hud
claude plugin install i-have-adhd@i-have-adhd
```

O `humanizer` NAO instala por plugin (manifesto invalido: chave `$schema`
rejeitada). Instalado por copia manual de
~/.claude/plugins/marketplaces/humanizer/SKILL.md para ~/.claude/skills/humanizer/.

Para remover qualquer um:
```bash
claude plugin uninstall claude-hud@claude-hud
claude plugin uninstall i-have-adhd@i-have-adhd
```
E para o humanizer, apagar a pasta ~/.claude/skills/humanizer.
