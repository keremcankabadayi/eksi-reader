#!/usr/bin/env bash
# Codespace core-hours usage widget for ccstatusline.
# Prints e.g. "CS 4/60h" (used/quota in real hours for THIS box's core count;
# GitHub's 120 core-hour free tier = 60h on 2-core, 30h on 4-core, 15h on
# 8-core). Never blocks: serves cache, refreshes in background when stale.
#
# Needs a GitHub CLASSIC PAT with the `user` scope. Fine-grained tokens are NOT
# supported by the billing usage API. Uses GH_TOKEN (Codespaces secret) by
# default; override with file ~/.config/ccstatusline/.gh-billing-token
#
# Codespaces on a personal repo are always billed to the user who started them,
# so the queried login defaults to GITHUB_USER, not the repo owner.
#
# Optional env:
#   GH_BILLING_USER       GitHub login (default: $GITHUB_USER)
#   CODESPACE_FREE_HOURS  override monthly included CORE-hours (else derived from
#                         account plan: free=120, pro=180). Displayed divided by
#                         this machine's core count.
#   CODESPACE_CORES       override core count (default: nproc)
#   CODESPACE_BUDGET      Codespaces spending limit in USD (default 5.00). The
#                         billing usage API does NOT expose the limit, so it is
#                         set here. "Spent" = sum of codespaces netAmount (the
#                         billed-beyond-included amount shown on GitHub's
#                         Codespaces "Stop usage" page).
#
# Output e.g. "CS 66/60h $1.09/$5" (core-hours used/quota, then spent/budget).

set -euo pipefail

CFG_DIR="$HOME/.config/ccstatusline"
CACHE="$HOME/.cache/ccstatusline-cs-usage.txt"
RAW="$HOME/.cache/ccstatusline-cs-usage.json"
TTL=1800   # 30 min
FREE_HOURS="${CODESPACE_FREE_HOURS:-}"   # empty = derive from account plan
BUDGET="${CODESPACE_BUDGET:-5.00}"       # Codespaces spending limit (USD)
CORES="${CODESPACE_CORES:-$(nproc 2>/dev/null || echo 2)}"

token() {
  if [ -f "$CFG_DIR/.gh-billing-token" ]; then
    tr -d '[:space:]' < "$CFG_DIR/.gh-billing-token"; return
  fi
  printf '%s' "${GH_TOKEN:-}"
}

user() {
  if [ -n "${GH_BILLING_USER:-}" ]; then printf '%s' "$GH_BILLING_USER"; return; fi
  printf '%s' "${GITHUB_USER:-}"
}

refresh() {
  local tok usr json used
  tok="$(token)"; usr="$(user)"
  { [ -z "$tok" ] || [ -z "$usr" ]; } && return 0
  json="$(curl -s --max-time 12 \
    -H "Authorization: Bearer $tok" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/users/$usr/settings/billing/usage?year=$(date +%Y)&month=$(date +%-m)")" || return 0
  printf '%s' "$json" > "$RAW"
  # included core-hours: env override, else derived from account plan
  local quota="$FREE_HOURS"
  if [ -z "$quota" ]; then
    local plan
    plan="$(curl -s --max-time 8 \
      -H "Authorization: Bearer $tok" \
      -H "Accept: application/vnd.github+json" \
      "https://api.github.com/user" \
      | node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{try{process.stdout.write(((JSON.parse(d).plan||{}).name||""))}catch(e){process.stdout.write("")}})')"
    case "$plan" in
      pro) quota=180;;
      *)   quota=120;;   # free + fallback
    esac
  fi

  # sum codespaces compute -> core-hours, then display as real hours on this
  # box (core-hours / cores). Free 120ch: 60h on 2-core, 30h on 4-core.
  local out
  out="$(printf '%s' "$json" | QC="$quota" BUD="$BUDGET" CORES="$CORES" node -e '
    let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{
      try{
        const j=JSON.parse(d);
        let ch=0, spent=0;
        for(const it of (j.usageItems||[])){
          const prod=(it.product||"").toLowerCase();
          const sku=(it.sku||"").toLowerCase();
          const unit=(it.unitType||"").toLowerCase();
          if(!prod.includes("codespace")) continue;
          spent+=Number(it.netAmount)||0;         // billed-beyond-included USD
          if(sku.includes("storage")||unit.includes("gb")) continue; // compute only
          let q=Number(it.quantity)||0;
          if(unit.includes("minute")) q=q/60;
          else if(unit.includes("second")) q=q/3600;
          const m=sku.match(/(\d+)\s*-?\s*core/);
          ch+=q*(m?Number(m[1]):1);              // core-hours
        }
        const qc=Number(process.env.QC)||120;
        const cores=Number(process.env.CORES)||2;
        const bud=Number(process.env.BUD)||5;
        const budStr=bud%1?bud.toFixed(2):String(bud); // "5" not "5.00"
        process.stdout.write("CS "+Math.round(ch/cores)+"/"+Math.round(qc/cores)+"h "
          +"$"+spent.toFixed(2)+"/$"+budStr);
      }catch(e){process.stdout.write("");}
    });' )"
  [ -z "$out" ] && return 0
  printf '%s' "$out" > "$CACHE"
}

if [ "${1:-}" = "--refresh" ]; then
  refresh
  exit 0
fi

# stale check -> kick background refresh
now=$(date +%s)
mt=0; [ -f "$CACHE" ] && mt=$(stat -c %Y "$CACHE" 2>/dev/null || echo 0)
if [ $((now - mt)) -ge "$TTL" ]; then
  ( "$0" --refresh >/dev/null 2>&1 & ) >/dev/null 2>&1 || true
fi

if [ -f "$CACHE" ]; then cat "$CACHE"; else printf 'CS ...'; fi
