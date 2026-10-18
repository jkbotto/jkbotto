<#
    instalar-enxuto.ps1 — versao enxuta de skills do Claude Code (Windows)

    Uso:
        powershell -ExecutionPolicy Bypass -File .\instalar-enxuto.ps1
        powershell -ExecutionPolicy Bypass -File .\instalar-enxuto.ps1 -Limpar

    -Limpar  remove primeiro a versao inchada (ECC, document-skills, claude-api e as
             skills avulsas fora da lista) e depois instala o conjunto enxuto.
#>

[CmdletBinding()]
param(
    [switch]$Limpar
)

# Mude para $false para NAO instalar os opcionais (superpowers, ui-ux-pro-max,
# impeccable, react-best-practices). Ver README.md para o racional.
$InstalarOpcionais = $true

$ErrorActionPreference = 'Continue'
$falhas = New-Object System.Collections.Generic.List[string]
$feitos = New-Object System.Collections.Generic.List[string]

$SkillsDir = Join-Path $HOME '.claude\skills'
$Manter = @(
    'eval-driven-dev', 'humanizer', 'screenshot',
    'security-best-practices', 'security-threat-model'
)
if ($InstalarOpcionais) { $Manter += 'react-best-practices' }

function Write-Passo($texto) { Write-Host ""; Write-Host "==> $texto" -ForegroundColor Cyan }
function Write-Ok($texto)    { Write-Host "    OK   $texto" -ForegroundColor Green }
function Write-Falha($texto) { Write-Host "    FALHA $texto" -ForegroundColor Red }

function Write-Pulado($texto) { Write-Host "    -    $texto" -ForegroundColor DarkGray }

# Estado atual, consultado UMA vez. Reinstalar por cima falha no Windows com EPERM
# (a sessao do Claude Code em execucao mantem lock nos diretorios), entao pulamos
# o que ja existe em vez de tentar e reportar erro falso.
$script:MktInstalados  = @()
$script:PlugInstalados = @()

function Atualizar-Estado {
    $script:MktInstalados = @()
    $script:PlugInstalados = @()
    $mkt = & claude plugin marketplace list 2>&1 | Out-String
    $plg = & claude plugin list 2>&1 | Out-String
    foreach ($linha in ($mkt -split "`r?`n")) {
        if ($linha -match '^\s*[>*-]?\s*([A-Za-z0-9._@\/-]+)\s*$') { $script:MktInstalados += $matches[1] }
    }
    foreach ($linha in ($plg -split "`r?`n")) {
        if ($linha -match '^\s*>\s*(\S+)') { $script:PlugInstalados += $matches[1] }
    }
}

function Add-Marketplace {
    param([string]$Fonte)
    # nome do marketplace nao e sempre igual ao repo, entao testamos as duas formas
    $curto = ($Fonte -split '/')[-1]
    if (($script:MktInstalados -contains $Fonte) -or ($script:MktInstalados -contains $curto)) {
        Write-Pulado "marketplace $Fonte (ja registrado)"; return
    }
    $saida = & claude plugin marketplace add $Fonte 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0) { Write-Ok "marketplace $Fonte"; $feitos.Add("marketplace $Fonte") }
    elseif ($saida -match 'EPERM|already') {
        Write-Pulado "marketplace $Fonte (ja existe / diretorio em uso)"
    }
    else { Write-Falha "marketplace $Fonte"; $falhas.Add("marketplace $Fonte") }
}

function Add-Plugin {
    param([string]$Plug)
    if ($script:PlugInstalados -contains $Plug) {
        Write-Pulado "plugin $Plug (ja instalado)"; return
    }
    $saida = & claude plugin install $Plug 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0) { Write-Ok "plugin $Plug"; $feitos.Add("plugin $Plug") }
    elseif ($saida -match 'EPERM') {
        Write-Falha "plugin $Plug (EPERM: feche o Claude Code e rode de novo)"
        $falhas.Add("plugin $Plug (diretorio em uso - feche o Claude Code)")
    }
    else { Write-Falha "plugin $Plug"; $falhas.Add("plugin $Plug") }
}

function Copy-Skill {
    param([string]$Origem, [string]$Nome)
    if (-not (Test-Path $Origem)) { Write-Falha "$Nome (origem ausente: $Origem)"; $falhas.Add($Nome); return }
    $destino = Join-Path $SkillsDir $Nome
    if (Test-Path $destino) { cmd /c "rmdir /s /q `"$destino`"" 2>$null }
    Copy-Item $Origem $destino -Recurse -Force
    if (Test-Path (Join-Path $destino 'SKILL.md')) { Write-Ok $Nome; $feitos.Add($Nome) }
    else { Write-Falha "$Nome (SKILL.md ausente apos a copia)"; $falhas.Add($Nome) }
}

# ---- pre-requisitos -----------------------------------------------------------
Write-Passo "Verificando pre-requisitos"
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Host "Claude Code CLI ('claude') nao encontrado no PATH. Abortando." -ForegroundColor Red
    exit 1
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "'git' nao encontrado no PATH. Abortando." -ForegroundColor Red
    exit 1
}
Write-Ok "claude e git presentes"
New-Item -ItemType Directory -Force $SkillsDir | Out-Null
Atualizar-Estado
Write-Ok "estado atual: $($script:PlugInstalados.Count) plugins, $($script:MktInstalados.Count) marketplaces"

# ---- limpeza opcional ---------------------------------------------------------
if ($Limpar) {
    Write-Passo "Removendo a versao inchada"
    foreach ($p in @('ecc@ecc', 'document-skills@anthropic-agent-skills', 'claude-api@anthropic-agent-skills')) {
        & claude plugin uninstall $p 2>&1 | Out-String | Write-Verbose
        if ($LASTEXITCODE -eq 0) { Write-Ok "desinstalado $p" } else { Write-Host "    -    $p nao estava instalado" -ForegroundColor DarkGray }
    }
    $removidas = 0
    foreach ($d in (Get-ChildItem $SkillsDir -Directory -ErrorAction SilentlyContinue)) {
        if ($Manter -notcontains $d.Name) {
            cmd /c "rmdir /s /q `"$($d.FullName)`"" 2>$null
            if (-not (Test-Path $d.FullName)) { $removidas++ }
        }
    }
    Write-Ok "$removidas skills avulsas removidas de ~/.claude/skills"
}

# ---- plugins do nucleo --------------------------------------------------------
Write-Passo "Instalando plugins do nucleo"
$nucleo = @(
    @{ mkt = 'anthropics/skills';        plug = 'example-skills@anthropic-agent-skills' },
    @{ mkt = 'jarrodwatts/claude-hud';   plug = 'claude-hud@claude-hud' },
    @{ mkt = 'ayghri/i-have-adhd';       plug = 'i-have-adhd@i-have-adhd' }
)
foreach ($item in $nucleo) {
    Add-Marketplace $item.mkt
    Add-Plugin $item.plug
}

# ---- plugins opcionais --------------------------------------------------------
if ($InstalarOpcionais) {
    Write-Passo "Instalando plugins opcionais"
    $opc = @(
        @{ mkt = 'obra/superpowers-marketplace';           plug = 'superpowers@superpowers-marketplace' },
        @{ mkt = 'nextlevelbuilder/ui-ux-pro-max-skill';   plug = 'ui-ux-pro-max@ui-ux-pro-max-skill' },
        @{ mkt = 'pbakaus/impeccable';                     plug = 'impeccable@impeccable' }
    )
    foreach ($item in $opc) {
        Add-Marketplace $item.mkt
        Add-Plugin $item.plug
    }
} else {
    Write-Passo "Opcionais desligados (`$InstalarOpcionais = `$false)"
}

# ---- skills avulsas -----------------------------------------------------------
Write-Passo "Clonando repositorios das skills avulsas"
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("skills-enxuto-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Force $tmp | Out-Null

try {
    # openai/skills — 3 skills curadas (repo depreciado, mas estas tres valem)
    git clone --depth 1 --filter=blob:none --sparse https://github.com/openai/skills.git "$tmp\openai" 2>&1 | Out-Null
    if (Test-Path "$tmp\openai") {
        Push-Location "$tmp\openai"
        git sparse-checkout set skills/.curated/security-best-practices skills/.curated/security-threat-model skills/.curated/screenshot 2>&1 | Out-Null
        Pop-Location
        foreach ($n in @('security-best-practices', 'security-threat-model', 'screenshot')) {
            Copy-Skill "$tmp\openai\skills\.curated\$n" $n
        }
    } else { Write-Falha "clone de openai/skills"; $falhas.Add('openai/skills') }

    # github/awesome-copilot — eval-driven-dev (repo grande, sparse obrigatorio)
    git clone --depth 1 --filter=blob:none --sparse https://github.com/github/awesome-copilot.git "$tmp\copilot" 2>&1 | Out-Null
    if (Test-Path "$tmp\copilot") {
        Push-Location "$tmp\copilot"
        git sparse-checkout set skills/eval-driven-dev 2>&1 | Out-Null
        Pop-Location
        Copy-Skill "$tmp\copilot\skills\eval-driven-dev" 'eval-driven-dev'
    } else { Write-Falha "clone de github/awesome-copilot"; $falhas.Add('awesome-copilot') }

    # blader/humanizer — SKILL.md na raiz; plugin install falha (chave $schema invalida)
    git clone --depth 1 https://github.com/blader/humanizer.git "$tmp\humanizer" 2>&1 | Out-Null
    if (Test-Path "$tmp\humanizer\SKILL.md") {
        $dst = Join-Path $SkillsDir 'humanizer'
        New-Item -ItemType Directory -Force $dst | Out-Null
        Copy-Item "$tmp\humanizer\SKILL.md" (Join-Path $dst 'SKILL.md') -Force
        if (Test-Path "$tmp\humanizer\LICENSE") { Copy-Item "$tmp\humanizer\LICENSE" (Join-Path $dst 'LICENSE') -Force }
        Write-Ok 'humanizer'; $feitos.Add('humanizer')
    } else { Write-Falha "humanizer (SKILL.md nao encontrado na raiz do repo)"; $falhas.Add('humanizer') }

    # vercel-labs/agent-skills — react-best-practices (opcional)
    if ($InstalarOpcionais) {
        git clone --depth 1 https://github.com/vercel-labs/agent-skills.git "$tmp\vercel" 2>&1 | Out-Null
        Copy-Skill "$tmp\vercel\skills\react-best-practices" 'react-best-practices'
    }
}
finally {
    Write-Passo "Limpando diretorio temporario"
    cmd /c "rmdir /s /q `"$tmp`"" 2>$null
    if (Test-Path $tmp) { Write-Host "    -    nao foi possivel remover $tmp (remova manualmente)" -ForegroundColor DarkGray }
    else { Write-Ok "temporario removido" }
}

# ---- verificacao --------------------------------------------------------------
Write-Passo "Verificando"
$semSkillMd = @()
foreach ($d in (Get-ChildItem $SkillsDir -Directory -ErrorAction SilentlyContinue)) {
    if (-not (Test-Path (Join-Path $d.FullName 'SKILL.md'))) {
        # pastas vazias sao restos de plugins removidos (ex: 'learned', do ECC) - descarta
        if ((Get-ChildItem $d.FullName -Force -Recurse -ErrorAction SilentlyContinue).Count -eq 0) {
            cmd /c "rmdir /s /q `"$($d.FullName)`"" 2>$null
            Write-Pulado "$($d.Name) (pasta vazia removida)"
        }
        else { $semSkillMd += $d.Name }
    }
}
if ($semSkillMd.Count -eq 0) { Write-Ok "todas as skills avulsas tem SKILL.md" }
else { Write-Falha ("sem SKILL.md: " + ($semSkillMd -join ', ')) }

Write-Host ""
Write-Host "Skills avulsas em ~/.claude/skills:" -ForegroundColor Cyan
Get-ChildItem $SkillsDir -Directory -ErrorAction SilentlyContinue | ForEach-Object { "  - " + $_.Name }
Write-Host ""
Write-Host "Plugins instalados:" -ForegroundColor Cyan
& claude plugin list

# ---- resumo -------------------------------------------------------------------
Write-Host ""
Write-Host "-------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "Concluido: $($feitos.Count) itens." -ForegroundColor Green
if ($falhas.Count -gt 0) {
    Write-Host "Falhas: $($falhas.Count)" -ForegroundColor Red
    $falhas | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
}
Write-Host ""
Write-Host "PROXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "  1. Reinicie o Claude Code (skills so entram em sessoes novas)."
Write-Host "  2. Rode /claude-hud:setup numa sessao interativa para a barra de status."
Write-Host "-------------------------------------------------------------" -ForegroundColor DarkGray
