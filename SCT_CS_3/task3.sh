#!/bin/bash

MIN_LENGTH=8
MAX_LENGTH=64
COLOR_RESET='\033[0m'
SCORE=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'

fail() {
    echo -e "${RED}[ERROR]${COLOR_RESET} $1"
    exit 1
}

check_length() {
    local len=${#1}
    if (( len < MIN_LENGTH )); then
        echo -e "${RED}✗ Too short (min ${MIN_LENGTH} chars)${COLOR_RESET}"
        return 0
    elif (( len > MAX_LENGTH )); then
        echo -e "${YELLOW}⚠ Too long (max ${MAX_LENGTH} chars)${COLOR_RESET}"
        return $((MAX_LENGTH / 2))
    else
        local score=$((len * 2))
        echo -e "${GREEN}✓ Length: ${len} (+${score})${COLOR_RESET}"
        return $score
    fi
}

check_uppercase() {
    [[ "$1" =~ [A-Z] ]] && echo -e "${GREEN}✓ Uppercase letters (+10)${COLOR_RESET}" && return 10
    echo -e "${RED}✗ No uppercase letters${COLOR_RESET}"
    return 0
}

check_lowercase() {
    [[ "$1" =~ [a-z] ]] && echo -e "${GREEN}✓ Lowercase letters (+10)${COLOR_RESET}" && return 10
    echo -e "${RED}✗ No lowercase letters${COLOR_RESET}"
    return 0
}

check_numbers() {
    local count=$(grep -o '[0-9]' <<< "$1" | wc -l)
    (( count > 0 )) && echo -e "${GREEN}✓ Numbers (${count} found, +$((count * 5)))${COLOR_RESET}" && return $((count * 5))
    echo -e "${RED}✗ No numbers${COLOR_RESET}"
    return 0
}

check_special_chars() {
    local count=$(echo -n "$1" | tr -d '[:alnum:]' | wc -c)
    if (( count > 0 )); then
        local score=$((count * 10))
        echo -e "${GREEN}✓ Special chars (${count} found, +${score})${COLOR_RESET}"
        return $score
    fi
    echo -e "${RED}✗ No special characters${COLOR_RESET}"
    return 0
}

check_common_patterns() {
    local common=("password" "123456" "qwerty" "letmein" "admin" "welcome")
    for pattern in "${common[@]}"; do
        if [[ "${1,,}" =~ $pattern ]]; then
            echo -e "${RED}⚠ Common pattern detected ('$pattern') (-20)${COLOR_RESET}"
            return 255  # Return 255 to later subtract 20
        fi
    done
    echo -e "${GREEN}✓ No common patterns${COLOR_RESET}"
    return 0
}

evaluate_score() {
    local score=$1
    local max_score=150
    local percentage=$((score * 100 / max_score))
    (( percentage > 100 )) && percentage=100

    local bar_length=50
    local filled=$((percentage * bar_length / 100))
    local bar="${GREEN}"
    for ((i = 0; i < filled; i++)); do bar+="■"; done
    bar+="${RED}"
    for ((i = filled; i < bar_length; i++)); do bar+="■"; done
    bar+="${COLOR_RESET}"

    local rating
    if (( percentage >= 80 )); then
        rating="${GREEN}Excellent${COLOR_RESET} 🔒"
    elif (( percentage >= 60 )); then
        rating="${GREEN}Strong${COLOR_RESET} 👍"
    elif (( percentage >= 40 )); then
        rating="${YELLOW}Moderate${COLOR_RESET} 🤔"
    elif (( percentage >= 20 )); then
        rating="${YELLOW}Weak${COLOR_RESET} ⚠"
    else
        rating="${RED}Very Weak${COLOR_RESET} ❌"
    fi

    echo -e "\n${WHITE}STRENGTH ASSESSMENT:${COLOR_RESET}"
    echo -e "  ${bar}"
    echo -e "  Score: ${PURPLE}${score}${COLOR_RESET}/${max_score} (${percentage}%)"
    echo -e "  Rating: ${rating}\n"

    if (( percentage < 60 )); then
        suggestions=()

        (( ${#password} < MIN_LENGTH )) && suggestions+=("- Use at least ${MIN_LENGTH} characters")
        [[ ! "$password" =~ [A-Z] ]] && suggestions+=("- Add uppercase letters")
        [[ ! "$password" =~ [a-z] ]] && suggestions+=("- Add lowercase letters")
        [[ ! "$password" =~ [0-9] ]] && suggestions+=("- Add numbers")
        (( $(echo -n "$password" | tr -d '[:alnum:]' | wc -c) == 0 )) && suggestions+=("- Add special characters")

        if (( ${#suggestions[@]} > 0 )); then
            echo -e "${CYAN}Recommendations:${COLOR_RESET}"
            for s in "${suggestions[@]}"; do echo "$s"; done
            echo ""
        fi
    fi
}

main() {
    clear
    echo -e "${BLUE}"
    echo "  ____                                _    _             _            "
    echo " |  _ \ __ _ ___ _____      ___ __  | |  | | ___  _ __ | |_ ___ _ __ "
    echo " | |_) / _\` / __/ __\ \ /\ / / '_ \ | |  | |/ _ \| '_ \| __/ _ \ '__|"
    echo " |  __/ (_| \__ \__ \\\ V  V /| | | || |__| | (_) | | | | ||  __/ |   "
    echo " |_|   \__,_|___/___/ \_/\_/ |_| |_| \____/ \___/|_| |_|\__\___|_|   "
    echo -e "${COLOR_RESET}"
    echo -e "${YELLOW}Password Strength Assessment Tool${COLOR_RESET}"
    echo -e "-------------------------------------------------------------------\n"

    echo -n -e "${WHITE}Enter password to assess: ${COLOR_RESET}"
    read password
    echo -e "\n"

    check_length "$password"; SCORE=$((SCORE + $?))
    check_uppercase "$password"; SCORE=$((SCORE + $?))
    check_lowercase "$password"; SCORE=$((SCORE + $?))
    check_numbers "$password"; SCORE=$((SCORE + $?))
    check_special_chars "$password"; SCORE=$((SCORE + $?))
    check_common_patterns "$password"
    [[ $? -eq 255 ]] && SCORE=$((SCORE - 20))

    (( SCORE < 0 )) && SCORE=0
    evaluate_score "$SCORE"
    unset password
}

main
