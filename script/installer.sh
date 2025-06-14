#!/bin/bash
# Variables
NGROK_SERVICE_FILE="/etc/systemd/system/ngrok.service"
CONFIG_DIR="$HOME/.config/ngrok"
INSTALLER_LOG="/tmp/ngrok-installer.log"

# Definición de colores
ROJO='\033[0;31m'
VERDE='\033[0;32m'
AMARILLO='\033[1;33m'
CIA='\033[0;36m'
SIN_COLOR='\033[0m'

# Verificar permisos de root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${ROJO}Ejecuta con sudo: sudo bash $0${SIN_COLOR}" >&2
        exit 1
    fi
}

# Instalar Ngrok
install_ngrok_binary() {
    echo -e "${AMARILLO}Instalando Ngrok...${SIN_COLOR}"
    local arch
    arch=$(uname -m)
    local url
    
    case $arch in
        x86_64) url="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz" ;;
        i*86)   url="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-386.tgz" ;;
        armv7*) url="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm.tgz" ;;
        aarch64) url="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm64.tgz" ;;
        *) 
            echo -e "${ROJO}Arquitectura no soportada: $arch${SIN_COLOR}" >&2
            exit 1
            ;;
    esac

    curl -s "$url" | tar xz -C /usr/local/bin
    chmod +x /usr/local/bin/ngrok
}

# Obtener token
get_token() {
    echo -e "${AMARILLO}Obtén tu token en: ${CIA}https://dashboard.ngrok.com/get-started/your-authtoken${SIN_COLOR}"
    local token_valid=false
    
    while [ "$token_valid" = false ]; do
        read -p "Ingresa tu token: " token
        if [ -n "$token" ]; then
            token_valid=true
        else
            echo -e "${ROJO}Token no puede estar vacío${SIN_COLOR}" >&2
        fi
    done
    echo "$token"
}

# Configurar servicio
setup_system_service() {
    local user=${SUDO_USER:-$(logname)}
    [ -z "$user" ] && user=$(ls /home | head -1)

    echo -e "${AMARILLO}Configurando servicio para usuario: $user${SIN_COLOR}"
    
    read -p "¿Qué puerto quieres exponer? (default: 22): " port
    port=${port:-22}
    
    echo -e "${AMARILLO}Regiones disponibles: us, eu, au, ap, sa, jp, in${SIN_COLOR}"
    read -p "¿Qué región deseas? (default: us): " region
    region=${region:-us}

    cat << EOF > "$NGROK_SERVICE_FILE"
[Unit]
Description=Ngrok Secure Tunnel
After=network.target

[Service]
Type=simple
User=$user
ExecStart=/usr/local/bin/ngrok tcp --log=stdout --region=$region $port
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable ngrok.service
}

# Comandos personalizados
setup_commands() {
    cat << 'EOF' > /usr/local/bin/ngrok-start
#!/bin/bash
sudo systemctl start ngrok
EOF

    cat << 'EOF' > /usr/local/bin/ngrok-stop
#!/bin/bash
sudo systemctl stop ngrok
EOF

    chmod +x /usr/local/bin/ngrok-*
}

# Proceso principal
install_ngrok() {
    check_root
    install_ngrok_binary
    
    token=$(get_token)
    sudo -u ${SUDO_USER:-$USER} ngrok config add-authtoken "$token"
    
    setup_system_service
    setup_commands
    
    echo -e "\n${VERDE}Instalación completada!${SIN_COLOR}"
    echo -e "Comandos disponibles:"
    echo -e "  ${CIA}ngrok-start${SIN_COLOR}    - Iniciar túnel"
    echo -e "  ${CIA}ngrok-stop${SIN_COLOR}     - Detener túnel"
    echo -e "  ${CIA}journalctl -u ngrok.service -f${SIN_COLOR}  - Ver logs"
}

# Ejecutar instalación
install_ngrok
