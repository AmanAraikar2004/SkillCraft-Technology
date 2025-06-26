#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

validate_shift() {
    local shift=$1
    if ! [[ "$shift" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Error: Shift must be a positive integer${NC}"
        return 1
    elif (( shift < 1 || shift > 25 )); then
        echo -e "${RED}Error: Shift must be between 1 and 25${NC}"
        return 1
    fi
    return 0
}

caesar_transform() {
    local text="$1"
    local shift="$2"
    local operation="$3"
    local result=""

    [[ "$operation" == "decrypt" ]] && shift=$((26 - shift))

    for ((i=0; i<${#text}; i++)); do
        char="${text:$i:1}"
        ascii=$(printf "%d" "'$char")

        if [[ "$char" =~ [A-Z] ]]; then
            new_ascii=$(( (ascii - 65 + shift) % 26 + 65 ))
            result+=$(printf "\\$(printf '%03o' "$new_ascii")")
        elif [[ "$char" =~ [a-z] ]]; then
            new_ascii=$(( (ascii - 97 + shift) % 26 + 97 ))
            result+=$(printf "\\$(printf '%03o' "$new_ascii")")
        else
            result+="$char"
        fi
    done

    echo "$result"
}

display_header() {
    clear
    echo -e "${YELLOW}"
    echo "   ____                          ___      _           "
    echo "  / ___|__ _  ___  ___ ___ ___ |_ _|_ __(_)_ __ ___  "
    echo " | |   / _\` |/ _ \/ __/ __/ _ \| || '__| | '_ \` _ \ "
    echo " | |__| (_| |  __/\__ \__ \ (_) | || |  | | | | | | |"
    echo "  \____\__,_|\___||___/___/\___/___|_|  |_|_| |_| |_|"
    echo -e "${NC}"
    echo -e "${GREEN}Secure Text Encryption/Decryption Tool${NC}"
    echo "------------------------------------------------"
}

main_menu() {
    while true; do
        display_header
        echo -e "\n1. Encrypt text"
        echo "2. Decrypt text"
        echo "3. Exit"
        echo "------------------------------------------------"
        read -p "Enter your choice [1-3]: " choice

        case "$choice" in
            1)
                read -p "Enter text to encrypt: " text
                while true; do
                    read -p "Enter shift value (1-25): " shift
                    validate_shift "$shift" && break
                done
                encrypted=$(caesar_transform "$text" "$shift" "encrypt")
                echo -e "\n${GREEN}Encrypted text:${NC} $encrypted"
                read -p "Press [Enter] to continue..."
                ;;
            2)
                read -p "Enter text to decrypt: " text
                while true; do
                    read -p "Enter shift value (1-25): " shift
                    validate_shift "$shift" && break
                done
                decrypted=$(caesar_transform "$text" "$shift" "decrypt")
                echo -e "\n${GREEN}Decrypted text:${NC} $decrypted"
                read -p "Press [Enter] to continue..."
                ;;
            3)
                echo -e "\n${YELLOW}Exiting... Thank you for using the Caesar Cipher tool!${NC}"
                exit 0
                ;;
            *)
                echo -e "\n${RED}Invalid choice. Please select 1, 2, or 3.${NC}"
                sleep 1
                ;;
        esac
    done
}

main_menu
