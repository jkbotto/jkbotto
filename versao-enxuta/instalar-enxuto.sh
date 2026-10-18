#!/usr/bin/env bash
# instalar-enxuto.sh — versao enxuta de skills do Claude Code (macOS / Linux)
#
# Uso:
#     bash ./instalar-enxuto.sh
#     bash ./instalar-enxuto.sh --limpar
#
# --limpar  remove primeiro a versao inchada (ECC, document-skills, claude-api e as
#           skills avulsas fora da lista) e depois instala o conjunto enxuto.

set -uo pipefail

# Mude para false para NAO instalar os opcionais (superpowers, ui-ux-pro-max,
# impeccable, react-best-practices). Ver README.md para o racional.
INSTALAR_OPCIONAIS=true

LIMPAR=false
for arg in "$@"; do
  case "$arg" in
    --limpar) LIMPAR=true ;;
    *) echo "Argumento desconhecido: $arg" >&2; exit 2 ;;
  esac
done

SKILLS_DIR="$HOME/.claude/skills"
MANTER=(eval-driven-dev humanizer screenshot security-best-practices security-threat-model)
if [ "$INSTALAR_OPCIONAIS" = true ]; then MANTER+=(react-best-practices); fi

FEITOS=0
FALHAS=()

C_CYAN=$'\033[36m'; C_GREEN=$'\033[32m'; C_RED=$'\033[31m'
C_GRAY=$'\033[90m'; C_YELLOW=$'\033[33m'; C_OFF=$'\033[0m'

passo() { printf '\n%s==> %s%s\n' "$C_CYAN" "$1" "$C_OFF"; }
ok()    { printf '    %sOK   %s%s\n' "$C_GREEN" "$1" "$C_OFF"; FEITOS=$((FEITOS+1)); }
falha() { printf '    %sFALHA %s%s\n' "$C_RED" "$1" "$C_OFF"; FALHAS+=("$1"); }
nota()  { printf '    %s-    %s%s\n' "$C_GRAY" "$1" "$C_OFF"; }

manter_contem() {
  local alvo="$1" m
  for m in "${MANTER[@]}"; do [ "$m" = "$alvo" ] && return 0; done
  return 1
}

copy_skill() {
  local origem="$1" nome="$2"
  if [ ! -d "$origem" ]; then falha "$nome (origem ausente: $origem)"; return; fi
  rm -rf "$SKILLS_DIR/$nome"
  cp -r "$origem" "$SKILLS_DIR/$nome"
  if [ -f "$SKILLS_DIR/$nome/SKILL.md" ]; then ok "$nome"
  else falha "$nome (SKILL.md ausente apos a copia)"; fi
}

# ---- pre-requisitos -----------------------------------------------------------
passo "Verificando pre-requisitos"
command -v claude >/dev/null 2>&1 || { echo "Claude Code CLI ('claude') nao encontrado no PATH. Abortando." >&2; exit 1; }
command -v git    >/dev/null 2>&1 || { echo "'git' nao encontrado no PATH. Abortando." >&2; exit 1; }
ok "claude e git presentes"
mkdir -p "$SKILLS_DIR"

# ---- limpeza opcional ---------------------------------------------------------
if [ "$LIMPAR" = true ]; then
  passo "Removendo a versao inchada"
  for p in ecc@ecc document-skills@anthropic-agent-skills claude-api@anthropic-agent-skills; do
    if claude plugin uninstall "$p" >/dev/null 2>&1; then ok "desinstalado $p"
    else nota "$p nao estava instalado"; fi
  done
  removidas=0
  for d in "$SKILLS_DIR"/*/; do
    [ -d "$d" ] || continue
    nome="$(basename "$d")"
    if ! manter_contem "$nome"; then rm -rf "$d" && removidas=$((removidas+1)); fi
  done
  ok "$removidas skills avulsas removidas de ~/.claude/skills"
fi

# ---- plugins ------------------------------------------------------------------
# Estado atual, consultado uma vez. Reinstalar por cima pode falhar se os diretorios
# estiverem em uso pela sessao do Claude Code, entao pulamos o que ja existe.
MKT_ATUAL="$(claude plugin marketplace list 2>&1 || true)"
PLUG_ATUAL="$(claude plugin list 2>&1 || true)"

instalar_plugin() {
  local mkt="$1" plug="$2" curto saida
  curto="${mkt##*/}"

  if printf '%s' "$MKT_ATUAL" | grep -qE "(^|[[:space:]])(${mkt//\//\\/}|${curto})([[:space:]]|$)"; then
    nota "marketplace $mkt (ja registrado)"
  else
    saida="$(claude plugin marketplace add "$mkt" 2>&1)"
    if [ $? -eq 0 ]; then ok "marketplace $mkt"
    elif printf '%s' "$saida" | grep -qiE 'already|EPERM'; then nota "marketplace $mkt (ja existe)"
    else falha "marketplace $mkt"; fi
  fi

  if printf '%s' "$PLUG_ATUAL" | grep -qF "> $plug"; then
    nota "plugin $plug (ja instalado)"
  else
    saida="$(claude plugin install "$plug" 2>&1)"
    if [ $? -eq 0 ]; then ok "plugin $plug"
    elif printf '%s' "$saida" | grep -qiE 'EPERM|in use'; then
      falha "plugin $plug (diretorio em uso - feche o Claude Code e rode de novo)"
    else falha "plugin $plug"; fi
  fi
}

passo "Instalando plugins do nucleo"
instalar_plugin anthropics/skills      example-skills@anthropic-agent-skills
instalar_plugin jarrodwatts/claude-hud claude-hud@claude-hud
instalar_plugin ayghri/i-have-adhd     i-have-adhd@i-have-adhd

if [ "$INSTALAR_OPCIONAIS" = true ]; then
  passo "Instalando plugins opcionais"
  instalar_plugin obra/superpowers-marketplace         superpowers@superpowers-marketplace
  instalar_plugin nextlevelbuilder/ui-ux-pro-max-skill ui-ux-pro-max@ui-ux-pro-max-skill
  instalar_plugin pbakaus/impeccable                   impeccable@impeccable
else
  passo "Opcionais desligados (INSTALAR_OPCIONAIS=false)"
fi

# ---- skills avulsas -----------------------------------------------------------
passo "Clonando repositorios das skills avulsas"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/skills-enxuto-XXXXXX")"
TMP_LIMPO=false
limpar_tmp() {
  [ "$TMP_LIMPO" = true ] && return 0
  TMP_LIMPO=true
  passo "Limpando diretorio temporario"
  if rm -rf "$TMP"; then ok "temporario removido"; else nota "remova manualmente: $TMP"; fi
}
# rede de seguranca: se o script morrer no meio, o temporario ainda e removido
trap 'limpar_tmp' EXIT

# openai/skills — 3 skills curadas (repo depreciado, mas estas tres valem)
if git clone --depth 1 --filter=blob:none --sparse https://github.com/openai/skills.git "$TMP/openai" >/dev/null 2>&1; then
  git -C "$TMP/openai" sparse-checkout set \
    skills/.curated/security-best-practices \
    skills/.curated/security-threat-model \
    skills/.curated/screenshot >/dev/null 2>&1
  for n in security-best-practices security-threat-model screenshot; do
    copy_skill "$TMP/openai/skills/.curated/$n" "$n"
  done
else
  falha "clone de openai/skills"
fi

# github/awesome-copilot — eval-driven-dev (repo grande, sparse obrigatorio)
if git clone --depth 1 --filter=blob:none --sparse https://github.com/github/awesome-copilot.git "$TMP/copilot" >/dev/null 2>&1; then
  git -C "$TMP/copilot" sparse-checkout set skills/eval-driven-dev >/dev/null 2>&1
  copy_skill "$TMP/copilot/skills/eval-driven-dev" eval-driven-dev
else
  falha "clone de github/awesome-copilot"
fi

# blader/humanizer — SKILL.md na raiz; plugin install falha (chave $schema invalida)
if git clone --depth 1 https://github.com/blader/humanizer.git "$TMP/humanizer" >/dev/null 2>&1 \
   && [ -f "$TMP/humanizer/SKILL.md" ]; then
  mkdir -p "$SKILLS_DIR/humanizer"
  cp "$TMP/humanizer/SKILL.md" "$SKILLS_DIR/humanizer/SKILL.md"
  [ -f "$TMP/humanizer/LICENSE" ] && cp "$TMP/humanizer/LICENSE" "$SKILLS_DIR/humanizer/LICENSE"
  ok humanizer
else
  falha "humanizer (SKILL.md nao encontrado na raiz do repo)"
fi

# vercel-labs/agent-skills — react-best-practices (opcional)
if [ "$INSTALAR_OPCIONAIS" = true ]; then
  if git clone --depth 1 https://github.com/vercel-labs/agent-skills.git "$TMP/vercel" >/dev/null 2>&1; then
    copy_skill "$TMP/vercel/skills/react-best-practices" react-best-practices
  else
    falha "clone de vercel-labs/agent-skills"
  fi
fi

# limpa o temporario ANTES do resumo, para a ordem da saida fazer sentido
limpar_tmp

# ---- verificacao --------------------------------------------------------------
passo "Verificando"
sem_skill=()
for d in "$SKILLS_DIR"/*/; do
  [ -d "$d" ] || continue
  if [ ! -f "$d/SKILL.md" ]; then
    # pastas vazias sao restos de plugins removidos (ex: 'learned', do ECC) - descarta
    if [ -z "$(ls -A "$d" 2>/dev/null)" ]; then
      rmdir "$d" 2>/dev/null && nota "$(basename "$d") (pasta vazia removida)"
    else
      sem_skill+=("$(basename "$d")")
    fi
  fi
done
if [ ${#sem_skill[@]} -eq 0 ]; then ok "todas as skills avulsas tem SKILL.md"
else falha "sem SKILL.md: ${sem_skill[*]}"; fi

printf '\n%sSkills avulsas em ~/.claude/skills:%s\n' "$C_CYAN" "$C_OFF"
for d in "$SKILLS_DIR"/*/; do [ -d "$d" ] && echo "  - $(basename "$d")"; done
printf '\n%sPlugins instalados:%s\n' "$C_CYAN" "$C_OFF"
claude plugin list

# ---- resumo -------------------------------------------------------------------
printf '\n%s-------------------------------------------------------------%s\n' "$C_GRAY" "$C_OFF"
printf '%sConcluido: %s itens.%s\n' "$C_GREEN" "$FEITOS" "$C_OFF"
if [ ${#FALHAS[@]} -gt 0 ]; then
  printf '%sFalhas: %s%s\n' "$C_RED" "${#FALHAS[@]}" "$C_OFF"
  for f in "${FALHAS[@]}"; do printf '%s  - %s%s\n' "$C_RED" "$f" "$C_OFF"; done
fi
printf '\n%sPROXIMOS PASSOS:%s\n' "$C_YELLOW" "$C_OFF"
echo "  1. Reinicie o Claude Code (skills so entram em sessoes novas)."
echo "  2. Rode /claude-hud:setup numa sessao interativa para a barra de status."
printf '%s-------------------------------------------------------------%s\n' "$C_GRAY" "$C_OFF"
