#!/usr/bin/env bash
# Codespaces post-create for the eksi-reader repo: Claude Code + plugins + skills + rtk.
# Idempotent; safe to re-run. Node 22 comes from the devcontainer feature.
# rtk and bun are symlinked into /usr/local/bin so Claude hooks find them on the
# default PATH regardless of login-shell rc files (avoids the "command not found"
# hook failures that block prompts).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

echo "== system deps (unzip for bun installer; lsof for dev-server port cleanup) =="
sudo apt-get update -qq && sudo apt-get install -y unzip lsof

echo "== Claude Code CLI =="
npm install -g @anthropic-ai/claude-code

echo "== bun (required at runtime by claude-mem) =="
[ -x "$HOME/.bun/bin/bun" ] || curl -fsSL https://bun.sh/install | bash
sudo ln -sf "$HOME/.bun/bin/bun" /usr/local/bin/bun
grep -q '.bun/bin' "$HOME/.bashrc" 2>/dev/null || echo 'export PATH="$HOME/.bun/bin:$PATH"' >> "$HOME/.bashrc"

echo "== cc alias (claude --dangerously-skip-permissions) =="
grep -q "alias cc=" "$HOME/.bashrc" 2>/dev/null || echo 'alias cc="claude --dangerously-skip-permissions"' >> "$HOME/.bashrc"
grep -q "alias ccr=" "$HOME/.bashrc" 2>/dev/null || echo 'alias ccr="claude --dangerously-skip-permissions --resume"' >> "$HOME/.bashrc"

echo "== rtk (Rust Token Killer) =="
curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh || true
sudo ln -sf "$HOME/.local/bin/rtk" /usr/local/bin/rtk
grep -q '.local/bin' "$HOME/.bashrc" 2>/dev/null || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"

echo "== graphify (graphifyy PyPI pkg + skill register) =="
command -v uv >/dev/null 2>&1 || curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"
uv tool install graphifyy || true
sudo ln -sf "$HOME/.local/bin/graphify" /usr/local/bin/graphify 2>/dev/null || true
graphify install || true

echo "== gh cross-repo auth =="
# Auth comes from the GH_TOKEN Codespaces secret (declared in devcontainer.json;
# classic PAT with repo/workflow/read:org) - gh reads it from the env, so no
# login survives-rebuild dance is needed.
# Codespaces also injects a repo-scoped GITHUB_TOKEN; if GH_TOKEN were missing,
# gh would silently fall back to it and lose cross-repo access. The wrapper
# hides GITHUB_TOKEN from gh so auth is GH_TOKEN or nothing. /usr/local/bin
# wins PATH over the feature-installed /usr/bin/gh.
sudo tee /usr/local/bin/gh >/dev/null <<'EOF'
#!/usr/bin/env bash
exec env -u GITHUB_TOKEN /usr/bin/gh "$@"
EOF
sudo chmod +x /usr/local/bin/gh
# Route git credentials for github.com through gh (clears the repo-scoped
# codespaces helper from /etc/gitconfig for this user). Works as soon as
# GH_TOKEN is present in the environment.
git config --global --replace-all credential.helper ""
git config --global --add credential.helper "!gh auth git-credential"

echo "== statusline config =="
# eksi-reader-claude-config is a named volume; a fresh volume mounts as root:root,
# which would silently break the cp calls below (script has no -e to catch it).
sudo chown vscode:vscode "$HOME/.claude"
mkdir -p "$HOME/.config/ccstatusline" "$HOME/.claude"
cp "$HERE/ccstatusline-settings.json" "$HOME/.config/ccstatusline/settings.json"
cp "$HERE/claude-settings.json" "$HOME/.claude/settings.json"
# Global user memory (prefixed names so the subdir doesn't auto-load as context).
cp "$HERE/claude-CLAUDE.md" "$HOME/.claude/CLAUDE.md"
cp "$HERE/claude-RTK.md" "$HOME/.claude/RTK.md"
cp "$HERE/codespace-usage.sh" "$HOME/.config/ccstatusline/codespace-usage.sh"
chmod +x "$HOME/.config/ccstatusline/codespace-usage.sh"

echo "== skip Claude first-run onboarding (theme + login wizard + workspace trust) =="
# Mark onboarding done, pin dark theme, and pre-accept the workspace trust dialog
# for this repo so tasks don't block waiting on that prompt. Auth comes from the
# CLAUDE_CODE_OAUTH_TOKEN Codespaces secret (declared in devcontainer.json),
# which the CLI picks up from the environment - no login prompt. Caveat: Remote
# Control rejects this inference-only token; run `claude auth login` once if
# remote control is needed.
node -e 'const fs=require("fs"),os=require("os"),p=os.homedir()+"/.claude.json";let d={};try{d=JSON.parse(fs.readFileSync(p))}catch(e){};d.hasCompletedOnboarding=true;d.theme="dark";d.projects=d.projects||{};d.projects["/workspaces/eksi-reader"]=Object.assign({},d.projects["/workspaces/eksi-reader"],{hasTrustDialogAccepted:true});fs.writeFileSync(p,JSON.stringify(d,null,2))' || true

echo "== marketplaces =="
for m in \
  anthropics/claude-plugins-official \
  JuliusBrussee/caveman \
  thedotmack/claude-mem \
  https://github.com/affaan-m/ECC.git \
  Owloops/claude-powerline; do
  claude plugin marketplace add "$m" || true
done

echo "== plugins =="
for p in \
  superpowers@claude-plugins-official \
  frontend-design@claude-plugins-official \
  caveman@caveman \
  claude-mem@thedotmack \
  ecc@ecc \
  claude-powerline@claude-powerline; do
  claude plugin install "$p" || true
done

echo "== rtk auto-rewrite hook (global) =="
# --auto-patch: patch settings.json without the interactive [y/N] prompt.
# Without it, `rtk init -g` blocks forever in the non-interactive container build.
rtk init -g --auto-patch </dev/null || true

echo "== done. Auth via CLAUDE_CODE_OAUTH_TOKEN secret; 'claude auth login' only needed for remote control. =="
