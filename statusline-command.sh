#!/bin/sh
# Claude Code statusLine — context window + rate-limit progress bars
#
# TOKEN SOURCES (no "daily quota" field exists in the Claude Code JSON):
#
#   1. context_window.used_percentage  (primary, always present after 1st msg)
#      Fraction of the *current session* context window that has been filled.
#      Pre-calculated by Claude Code; null before the first API call.
#
#   2. rate_limits.five_hour / rate_limits.seven_day  (secondary, optional)
#      Claude.ai subscription rolling-window limits.  Only present for paid
#      subscribers *after* the first API response.  Absent otherwise.
#
#   ccusage / npx ccusage: not used — it measures per-project cost/tokens from
#   local JSONL logs, not the live session quota; would require a subprocess
#   that adds latency on every status-line refresh.

# ── helpers ──────────────────────────────────────────────────────────────────

# build_bar PCT WIDTH
#   Prints  [████░░░░░░░░░░░░░░░░]  with WIDTH inner chars, colored by PCT.
build_bar() {
  pct="$1"
  width="$2"

  # ANSI colors
  RED='\033[0;31m'
  YLW='\033[0;33m'
  GRN='\033[0;32m'
  RST='\033[0m'

  if [ "$(echo "$pct >= 80" | awk '{print ($1 >= $3)}')" -eq 1 ] 2>/dev/null || \
     [ "${pct%.*}" -ge 80 ] 2>/dev/null; then
    color="$RED"
  elif [ "${pct%.*}" -ge 50 ] 2>/dev/null; then
    color="$YLW"
  else
    color="$GRN"
  fi

  filled=$(echo "$pct $width" | awk '{f=int($1/100*$2+0.5); print (f>$2)?$2:f}')
  empty=$((width - filled))

  bar=""
  i=0
  while [ "$i" -lt "$filled" ]; do
    bar="${bar}█"
    i=$((i+1))
  done
  i=0
  while [ "$i" -lt "$empty" ]; do
    bar="${bar}░"
    i=$((i+1))
  done

  printf "${color}[%s]${RST} %s%%" "$bar" "$(printf '%.0f' "$pct")"
}

# fmt_k TOKENS  →  "123k" or "1.2M"
fmt_k() {
  echo "$1" | awk '{
    if ($1 >= 1000000) printf "%.1fM", $1/1000000
    else if ($1 >= 1000) printf "%.0fk", $1/1000
    else printf "%d", $1
  }'
}

# ── read JSON once ────────────────────────────────────────────────────────────
input=$(cat)

used_pct=$(echo "$input"    | jq -r '.context_window.used_percentage    // empty')
total_in=$(echo "$input"    | jq -r '.context_window.total_input_tokens  // empty')
ctx_size=$(echo "$input"    | jq -r '.context_window.context_window_size // empty')
five_pct=$(echo "$input"    | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "$input"    | jq -r '.rate_limits.seven_day.used_percentage // empty')

# ── context-window bar ────────────────────────────────────────────────────────
if [ -n "$used_pct" ]; then
  ctx_bar=$(build_bar "$used_pct" 20)

  # optional token counts
  if [ -n "$total_in" ] && [ -n "$ctx_size" ]; then
    tok_label=" $(fmt_k "$total_in")/$(fmt_k "$ctx_size")"
  else
    tok_label=""
  fi

  printf "ctx %s%s" "$ctx_bar" "$tok_label"
else
  # No messages yet — show an empty bar
  printf "ctx \033[0;32m[░░░░░░░░░░░░░░░░░░░░]\033[0m  0%%"
fi

# ── rate-limit indicators (subscriber only) ───────────────────────────────────
rl_out=""
if [ -n "$five_pct" ]; then
  five_bar=$(build_bar "$five_pct" 10)
  rl_out="  5h ${five_bar}"
fi
if [ -n "$week_pct" ]; then
  week_bar=$(build_bar "$week_pct" 10)
  rl_out="${rl_out}  7d ${week_bar}"
fi

[ -n "$rl_out" ] && printf "%s" "$rl_out"
