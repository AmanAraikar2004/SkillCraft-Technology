#!/bin/bash

DEPENDENCIES=("magick" "identify")
TEMP_DIR="/tmp/pixelcrypt"
mkdir -p "$TEMP_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

fail() {
    echo -e "${RED}[ERROR]${NC} $1"
    read -p "Press [Enter] to return to menu..."
}

check_dependencies() {
    for cmd in "${DEPENDENCIES[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo -e "${RED}Missing dependency: $cmd${NC}"
            echo -e "Install ImageMagick v7:\n  sudo apt install imagemagick"
            exit 1
        fi
    done
}

validate_image() {
    if ! identify "$1" &> /dev/null; then
        fail "Invalid or corrupt image file: $1"
        return 1
    fi
    return 0
}

validate_key() {
    if ! [[ "$1" =~ ^[0-9]+$ ]]; then
        fail "Key must be an integer!"
        return 1
    fi
    if (( "$1" < 1 || "$1" > 255 )); then
        fail "Key must be between 1 and 255"
        return 1
    fi
    return 0
}

xor_encrypt() {
    local input="$1" output="$2" key="$3"
    local overlay="$TEMP_DIR/xor_overlay.png"
    local width height
    read width height < <(identify -format "%w %h" "$input")

    magick -size ${width}x${height} canvas:"rgb($key,$key,$key)" "$overlay"
    magick "$input" "$overlay" -channel RGB -fx "u^v" "$output" || fail "XOR operation failed"
}

add_encrypt() {
    local input="$1" output="$2" key="$3"
    local overlay="$TEMP_DIR/add_overlay.png"
    local width height
    read width height < <(identify -format "%w %h" "$input")

    magick -size ${width}x${height} canvas:"rgb($key,$key,$key)" "$overlay"
    magick "$input" "$overlay" -compose Plus -composite "$output" || fail "Addition operation failed"
}

channel_swap() {
    local input="$1" output="$2" key="$3"
    local swap_choice=$((key % 3))

    case $swap_choice in
        0) magick "$input" -separate -swap 0,2 -combine "$output";;
        1) magick "$input" -separate -swap 1,2 -combine "$output";;
        2) magick "$input" -separate -swap 0,1 -combine "$output";;
    esac || fail "Channel swap failed"
}

encrypt_menu() {
    local input output method key

    while true; do
        read -p "Enter input image path: " input
        validate_image "$input" && break
    done

    while true; do
        read -p "Enter output image path: " output
        if [[ -e "$output" ]]; then
            read -p "File exists. Overwrite? (y/n): " ow
            [[ "$ow" == "y" ]] && break
        else
            break
        fi
    done

    echo -e "\nChoose encryption method:"
    echo "1) XOR"
    echo "2) Add/Subtract"
    echo "3) Channel Swap"
    while true; do
        read -p "Select (1-3): " method
        [[ "$method" =~ ^[1-3]$ ]] && break
        echo -e "${RED}Invalid selection!${NC}"
    done

    while true; do
        read -p "Enter encryption key (1-255): " key
        validate_key "$key" && break
    done

    case $method in
        1) xor_encrypt "$input" "$output" "$key" ;;
        2) add_encrypt "$input" "$output" "$key" ;;
        3) channel_swap "$input" "$output" "$key" ;;
    esac

    echo -e "\n${GREEN}Success!${NC} Output saved to: $output"
    read -p "Press [Enter] to continue..."
}

decrypt_menu() {
    echo -e "\n${YELLOW}NOTE:${NC} Use the same method and key used for encryption."
    encrypt_menu
}

main_menu() {
    while true; do
        clear
        echo -e "${YELLOW}"
        echo "   ____  _       __   ____                __   "
        echo "  / __ \\(_)___  / /_ / __ \\_________     / /__ "
        echo " / /_/ / / __ \\/ __// /_/ / ___/ __ \\   / //_/ "
        echo "/ ____/ / /_/ / /_ / _, _/ /__/ /_/ /  / ,<    "
        echo "/_/   /_/ .___/\__//_/ |_|\___/\____/  /_/|_|  "
        echo "       /_/                                     "
        echo -e "${NC}"
        echo -e "${BLUE}PixelCrypt - Image Encryption Tool${NC}"
        echo "----------------------------------------"
        echo "1) Encrypt Image  3) About"
        echo "2) Decrypt Image  4) Exit"
        echo "----------------------------------------"
        read -p "Choose an option (1-4): " choice

        case $choice in
            1) encrypt_menu ;;
            2) decrypt_menu ;;
            3)
                echo -e "\n${GREEN}PixelCrypt v2.0${NC} - Secure your images with visual crypto!"
                read -p "Press [Enter] to continue..."
                ;;
            4)
                echo -e "\n${GREEN}Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option!${NC}"
                sleep 1
                ;;
        esac
    done
}

check_dependencies
main_menu
