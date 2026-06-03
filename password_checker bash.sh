#!/bin/bash
# ================================================
#   Password Strength Analyzer - Bash Version
#   For educational use in cybersecurity course
# ================================================

# Colors
RED='\033[0;31m'
ORANGE='\033[0;33m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BLUE='\033[1;34m'
WHITE='\033[1;37m'
DIM='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Log file ────────────────────────────────────
LOG_FILE="password_log.txt"

# ── Header ──────────────────────────────────────
print_header() {
  clear
  echo -e "${CYAN}"
  echo "  ╔══════════════════════════════════════════╗"
  echo "  ║     // Security Tool v1.0                ║"
  echo "  ║                                          ║"
  echo "  ║   PASSWORD  ANALYZER                     ║"
  echo "  ╚══════════════════════════════════════════╝"
  echo -e "${RESET}"
}

# ── Strength bar ────────────────────────────────
print_bar() {
  local score=$1
  local color=$2
  local bar=""
  for i in 1 2 3 4 5; do
    if [ "$i" -le "$score" ]; then
      bar+="${color}█${RESET}"
    else
      bar+="${DIM}░${RESET}"
    fi
  done
  echo -e "  Strength  : $bar"
}

# ── Crack time estimate ──────────────────────────
crack_time() {
  local charset=$1
  local length=$2

  # Use python3 for big number math
  python3 - <<EOF
import math

charset = $charset
length = $length

if charset == 0 or length == 0:
    print("—")
else:
    combinations = charset ** length
    guesses_per_sec = 1e10  # GPU brute force
    seconds = combinations / guesses_per_sec / 2

    if seconds < 1:
        print("< 1 second")
    elif seconds < 60:
        print(f"~{round(seconds)} seconds")
    elif seconds < 3600:
        print(f"~{round(seconds/60)} minutes")
    elif seconds < 86400:
        print(f"~{round(seconds/3600)} hours")
    elif seconds < 2592000:
        print(f"~{round(seconds/86400)} days")
    elif seconds < 31536000:
        print(f"~{round(seconds/2592000)} months")
    elif seconds < 3.15e9:
        print(f"~{round(seconds/31536000)} years")
    elif seconds < 3.15e12:
        print(f"~{seconds/3.15e9:.1f}K years")
    elif seconds < 3.15e15:
        print(f"~{seconds/3.15e12:.1f}M years")
    else:
        print("∞  (heat death of universe)")
EOF
}

# ── Entropy calculation ──────────────────────────
calc_entropy() {
  local charset=$1
  local length=$2
  python3 -c "
import math
c = $charset
l = $length
if c > 0 and l > 0:
    print(f'{l * math.log2(c):.2f}')
else:
    print('0.00')
"
}

# ── Save log to file ────────────────────────────
save_log() {
  local pwd="$1"
  local label="$2"
  local crack="$3"
  local entropy="$4"
  local length="$5"
  local charset="$6"
  local unique="$7"
  local timestamp
  timestamp=$(date "+%Y-%m-%d %H:%M:%S")

  {
    echo "=================================================="
    echo "  PASSWORD ANALYZER LOG"
    echo "  Saved   : $timestamp"
    echo "=================================================="
    echo "  Password    : $pwd"
    echo "  Level       : $label"
    echo "  Crack time  : $crack"
    echo "  Entropy     : $entropy bits"
    echo "  Length      : $length"
    echo "  Charset size: $charset"
    echo "  Unique chars: $unique"
    echo ""
  } >> "$LOG_FILE"

  echo -e "  ${GREEN}✓ Saved to ${LOG_FILE}${RESET}\n"
}

# ── Analyze password ─────────────────────────────
analyze() {
  local pwd="$1"
  local length=${#pwd}

  # Criteria checks
  local has_upper=0 has_lower=0 has_digit=0 has_special=0
  local has_len8=0 has_len16=0

  [[ "$pwd" =~ [A-Z] ]]       && has_upper=1
  [[ "$pwd" =~ [a-z] ]]       && has_lower=1
  [[ "$pwd" =~ [0-9] ]]       && has_digit=1
  [[ "$pwd" =~ [^a-zA-Z0-9] ]] && has_special=1
  [ "$length" -ge 8 ]         && has_len8=1
  [ "$length" -ge 16 ]        && has_len16=1

  # Charset size
  local charset=0
  [ $has_lower   -eq 1 ] && charset=$((charset + 26))
  [ $has_upper   -eq 1 ] && charset=$((charset + 26))
  [ $has_digit   -eq 1 ] && charset=$((charset + 10))
  [ $has_special -eq 1 ] && charset=$((charset + 32))
  [ $charset -eq 0 ] && [ $length -gt 0 ] && charset=26

  # Score (0–5)
  local score=0
  [ $has_len8    -eq 1 ] && score=$((score + 1))
  [ $has_upper   -eq 1 ] && score=$((score + 1))
  [ $has_lower   -eq 1 ] && score=$((score + 1))
  ( [ $has_digit -eq 1 ] || [ $has_special -eq 1 ] ) && score=$((score + 1))
  ( [ $has_len16 -eq 1 ] || ( [ $has_special -eq 1 ] && [ $length -ge 12 ] ) ) && score=$((score + 1))

  # Level
  local label color
  case $score in
    0) label="CRITICAL" ; color=$RED    ;;
    1) label="WEAK"     ; color=$ORANGE ;;
    2) label="FAIR"     ; color=$YELLOW ;;
    3) label="GOOD"     ; color=$GREEN  ;;
    4) label="STRONG"   ; color=$GREEN  ;;
    5) label="FORTRESS" ; color=$CYAN   ;;
  esac
  _LAST_LABEL="$label"

  # Unique chars
  local unique
  unique=$(echo "$pwd" | grep -o . | sort -u | wc -l)

  # Entropy & crack time
  local entropy crack
  entropy=$(calc_entropy "$charset" "$length")
  crack=$(crack_time "$charset" "$length")

  # Expose to outer scope for save_log
  _LAST_PWD="$pwd"
  _LAST_CRACK="$crack"
  _LAST_ENTROPY="$entropy"
  _LAST_LENGTH="$length"
  _LAST_CHARSET="$charset"
  _LAST_UNIQUE="$unique"

  # ── Print results ──
  print_header

  echo -e "  ${DIM}// Enter password${RESET}"
  echo -e "  ${CYAN}$pwd${RESET}"
  echo ""

  # Strength bar
  print_bar "$score" "$color"
  echo -e "  Level     : ${color}${BOLD}$label${RESET}"
  echo -e "  Crack time: ${WHITE}$crack${RESET}"
  echo ""

  # Criteria
  echo -e "  ${DIM}── Criteria Check ─────────────────────${RESET}"

  check_icon() {
    [ "$1" -eq 1 ] && echo -e "${GREEN}✓${RESET}" || echo -e "${DIM}○${RESET}"
  }

  echo -e "  $(check_icon $has_len8)    Min. 8 characters     $(check_icon $has_upper)    Uppercase letter"
  echo -e "  $(check_icon $has_lower)    Lowercase letter      $(check_icon $has_digit)    Number (0–9)"
  echo -e "  $(check_icon $has_special)    Special character     $(check_icon $has_len16)    16+ characters"
  echo ""

  # Entropy & stats
  echo -e "  ${DIM}── Entropy & Stats ────────────────────${RESET}"
  printf "  %-20s ${CYAN}%s${RESET}\n" "length"       "$length"
  printf "  %-20s ${CYAN}%s${RESET}\n" "charset_size" "$charset"
  printf "  %-20s ${CYAN}%s bits${RESET}\n" "entropy_bits" "$entropy"
  printf "  %-20s ${CYAN}%s${RESET}\n" "unique_chars" "$unique"
  echo ""
}

# ── Main loop ────────────────────────────────────
print_header

while true; do
  echo -ne "  Enter password (or 'q' to quit): "
  # Read without echo for privacy
  read -rs pwd
  echo ""

  [ "$pwd" = "q" ] && {
    echo -e "\n  ${DIM}Exiting...${RESET}"
    [ -f "$LOG_FILE" ] && echo -e "  ${CYAN}Log saved → $LOG_FILE${RESET}"
    echo ""
    exit 0
  }
  [ -z "$pwd" ]    && echo -e "  ${RED}No password entered.${RESET}\n" && continue

  analyze "$pwd"

  save_log "$_LAST_PWD" "$_LAST_LABEL" "$_LAST_CRACK" \
           "$_LAST_ENTROPY" "$_LAST_LENGTH" "$_LAST_CHARSET" "$_LAST_UNIQUE"

  echo -ne "  ${DIM}Press Enter to check another...${RESET}"
  read -r
done
