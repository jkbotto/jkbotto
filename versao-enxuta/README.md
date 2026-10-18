# Claude Code — versão enxuta de skills

Pacote para instalar um conjunto **curado e pequeno** de skills no Claude Code, ou para
enxugar uma instalação que já saiu de controle.

## Por que existe

Instalamos em massa 10 repositórios de skills (~360 skills nossas, somadas às ~150 que
já vêm com o app). Depois auditamos tudo com 10 agentes trabalhando em pares — um
classificando cada skill, outro contestando criticamente a classificação do primeiro,
nas duas direções (cortes indevidos e permanências indevidas).

Resultado da auditoria, após a revisão cruzada:

| Grupo | Avaliadas | KEEP | CONDITIONAL | CUT |
|---|---|---|---|---|
| ECC (`affaan-m/ECC`) | 278 | 7 | 61 | 210 |
| superpowers + anthropic + ui-ux + impeccable | 40 | 2 | 2 | 36 |
| Avulsas (`openai/skills` etc.) | 43 | 0 | 6 | 37 |
| **Total** | **361** | **9** | **69** | **283** |

**9 KEEP em 361.** A instalação em massa é um anti-padrão: cada skill carregada compete
por ativação e infla o contexto de toda sessão.

## Os três achados que mais importam

**1. O ECC era 77% do problema — e não só por volume.** Além de 278 skills, ele registra
**20 hooks** que disparam em praticamente toda chamada de ferramenta, cada um abrindo um
processo Node novo. Entre eles: o *GateGuard*, que bloqueia a primeira escrita em cada
arquivo e exige uma "apresentação de fatos" antes de liberar; um `stop:format-typecheck`
com timeout de 300 segundos; um coletor de observações com `matcher: "*"`; e um
`stop:desktop-notify` que só funciona em macOS/WSL — código morto no Windows.

**2. Skills copiadas de outro agente não funcionam bem.** As 39 skills de
`openai/skills` são escritas para o **Codex**, não para o Claude Code. Os textos dizem
literalmente "Build a composable CLI for Codex", "Codex-compatible animated pets",
referenciam `CODEX_HOME` e caminhos Unix. O repositório inclusive está marcado como
depreciado pela própria OpenAI.

**3. Duplicação de gatilhos.** `docx` chegou a existir 3 vezes carregada
(app + plugin + avulsa) e `pdf` 4 vezes. Gatilhos idênticos competindo, sem ganho de
capacidade.

## O que a revisão cruzada pegou (e por que o método valeu)

Os revisores derrubaram achados concretos dos auditores:

- Um auditor cortou `cost-tracking` por "redundância". O revisor foi ao disco, achou
  `~/.claude/metrics/costs.jsonl` com 127 linhas escritas naquele mesmo dia, e provou
  uso ativo real.
- Um auditor cortou `screenshot` alegando "só macOS, sem ramo para Windows". O revisor
  abriu o arquivo: existe uma seção `## Windows (PowerShell helper)` com script completo.
  Premissa factualmente falsa — a skill ficou.
- Um auditor citou a própria regra errada: escreveu que "Go não estava na lista
  protegida" quando Go estava, e cortou `error-handling` por isso.

O padrão sistêmico que os cinco revisores identificaram foi o mesmo: os auditores eram
**severos ao cortar e frouxos consigo mesmos ao justificar as permanências**, usando
"redundante com X" como atalho retórico sem verificar se as skills competiam de fato
pelo mesmo gatilho.

Uma ressalva de honestidade: os agentes também erraram. Um revisor afirmou que
`document-skills`, `example-skills` e `claude-api` instalavam os mesmos 18 arquivos três
vezes. Falso — o `marketplace.json` mostra subconjuntos **disjuntos** (4 + 12 + 1). A
triplicação era de disco, não de skills. Os dois primeiros foram removidos por outro
motivo, verificado: o app já traz `anthropic-skills:docx/pdf/pptx/xlsx` e um
`claude-api` nativo.

## O que a versão enxuta instala

### Núcleo — defensável para qualquer perfil

| Item | Tipo | Para quê |
|---|---|---|
| `example-skills` | plugin | docx/pptx/xlsx, webapp-testing, mcp-builder, skill-creator — oficial da Anthropic |
| `claude-hud` | plugin | barra de status com contexto, ferramentas e progresso. Sem hooks |
| `i-have-adhd` | plugin | força resposta com a ação primeiro, passos numerados, sem divagação |
| `humanizer` | avulsa | remove marcas de texto gerado por IA |
| `eval-driven-dev` | avulsa | QA e avaliação de aplicações que chamam LLM |
| `security-best-practices` | avulsa | revisão de segurança por linguagem |
| `security-threat-model` | avulsa | modelagem de ameaças sobre um repositório |
| `screenshot` | avulsa | captura de tela ad hoc (tem suporte real a Windows) |

### Opcional — só se o perfil bater

| Item | Tipo | Quando vale |
|---|---|---|
| `superpowers` | plugin | metodologia de engenharia de software: TDD, git worktrees, code review, branches. **A auditoria cortou por não haver stack/repo em uso** — vale se você programa de fato |
| `ui-ux-pro-max` | plugin | paletas, tipografia, design system. Vale se você constrói interfaces |
| `impeccable` | plugin | passe de polimento em front-end. Mesma condição |
| `react-best-practices` | avulsa | só se usa React/Next.js |

Os opcionais vêm ligados por padrão nos scripts. Para pular, mude uma linha no topo
(`$InstalarOpcionais = $false` / `INSTALAR_OPCIONAIS=false`).

## Como aplicar

Três caminhos. O primeiro é o mais simples.

**1. Pelo prompt (qualquer sistema operacional)** — cole o conteúdo de
[`PROMPT-VERSAO-ENXUTA.md`](PROMPT-VERSAO-ENXUTA.md) numa sessão do Claude Code.

**2. Windows, determinístico:**

```powershell
powershell -ExecutionPolicy Bypass -File .\instalar-enxuto.ps1
```

**3. macOS/Linux, determinístico:**

```bash
bash ./instalar-enxuto.sh
```

Os dois scripts aceitam `-Limpar` / `--limpar` para **primeiro remover** a versão
inchada (ECC, `document-skills`, `claude-api` e as skills avulsas fora da lista) e
depois instalar o conjunto enxuto. Use isso em quem já rodou a instalação em massa.

## Depois de instalar

1. **Reinicie o Claude Code** — skills só entram em sessões novas.
2. Rode `/claude-hud:setup` numa sessão interativa para configurar a barra de status.
   Ele grava `statusLine` no `settings.json` e faz backup antes.

## Avisos

Os dois primeiros itens foram descobertos **testando os scripts de verdade**, não
supostos:

- **Reexecutar com o Claude Code aberto falha no Windows.** `claude plugin install` e
  `marketplace add` fazem `rename` de diretórios; a sessão em execução mantém lock neles
  e o comando aborta com `EPERM`. Não corrompe nada — a instalação existente continua
  íntegra. Os scripts contornam **consultando o estado antes** e pulando o que já existe;
  se ainda assim der `EPERM`, feche o Claude Code e rode de novo.
- **Pastas vazias em `~/.claude/skills`.** Plugins removidos deixam restos (o ECC deixa
  uma pasta `learned` vazia). Os scripts detectam e removem pastas sem `SKILL.md` que
  estejam vazias, em vez de reportar como erro.
- O `humanizer` **não instala** por `claude plugin install`: o manifesto dele usa uma
  chave `$schema` que o Claude Code rejeita. Os scripts contornam copiando o `SKILL.md`
  direto para `~/.claude/skills/humanizer/`.
- O `i-have-adhd` registra **1 hook** (`SessionStart`, timeout 5s) que roda um script
  `sh`. Ele é opt-in: só faz algo se existir o arquivo `~/.claude/.i-have-adhd-always`,
  e sai com 0 em qualquer falha. No Windows exige Git Bash no PATH — normalmente já vem
  com o Git.
- `git` e o Claude Code v2.x ou superior são pré-requisitos. Ambos os scripts abortam
  com mensagem clara se faltar algum.
- Nada aqui é irreversível: [`../ROLLBACK-SKILLS.md`](../ROLLBACK-SKILLS.md) documenta
  como voltar atrás, incluindo como trazer o ECC de volta **sem** os 20 hooks, via
  `ECC_GATEGUARD=off` e `ECC_DISABLED_HOOKS`.

### Uma skill não atribuída

Durante os testes apareceu uma pasta `find-skills` em `~/.claude/skills` que **não foi
instalada por este pacote**. Procurei em todos os marketplaces e caches clonados e não
achei a origem. O conteúdo é inofensivo (um assistente para descobrir e instalar
skills) e ela foi deixada no lugar — apagar algo cuja procedência não se conhece é pior
do que sinalizar. Se aparecer no ambiente de um colega, é isso. Para remover:
apague a pasta `~/.claude/skills/find-skills`.

## Aviso sobre o prompt antigo

O arquivo [`../PROMPT-INSTALAR-SKILLS.md`](../PROMPT-INSTALAR-SKILLS.md) instala a
**versão inchada** — os 10 repositórios, ~360 skills, ECC e seus 20 hooks incluídos.
Está mantido apenas como registro histórico. **Não distribua mais.** Use este pacote.
