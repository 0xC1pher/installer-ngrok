#!/bin/bash
# Ngrok SOCKS5 Proxy Installer para Arch Linux

NGROK_SERVICE_FILE="/etc/systemd/system/ngrok-socks.service"
DANTE_SERVICE_FILE="/etc/systemd/system/danted.service"
NGROK_CONFIG_DIR="/root/.config/ngrok"
NGROK_CONFIG_FILE="$NGROK_CONFIG_DIR/ngrok.yml"
SOCKS_PROXY_PORT=1080

ROJO='\033[0;31m'
VERDE='\033[0;32m'
AMARILLO='\033[1;33m'
CIA='\033[0;36m'
SIN_COLOR='\033[0m'

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${ROJO}ERROR: Ejecuta con sudo: sudo bash $0${SIN_COLOR}" >&2
        exit 1
    fi
}

install_dependencies() {
    echo -e "${AMARILLO}Instalando dependencias...${SIN_COLOR}"
    pacman -Sy --noconfirm curl jq dante nano || {
        echo -e "${ROJO}Error al instalar paquetes.${SIN_COLOR}"
        exit 1
    }

    arch=$(uname -m)
    case $arch in
        x86_64) url="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz" ;;
        aarch64) url="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm64.tgz" ;;
        armv7*) url="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm.tgz" ;;
        *) echo -e "${ROJO}Arquitectura no soportada: $arch${SIN_COLOR}"; exit 1 ;;
    esac

    echo -e "${AMARILLO}Descargando Ngrok...${SIN_COLOR}"
    curl -fL "$url" | tar xz -C /usr/local/bin || {
        echo -e "${ROJO}Error al descargar Ngrok.${SIN_COLOR}"
        exit 1
    }
    chmod +x /usr/local/bin/ngrok
}

configure_ngrok() {
    echo -e "${AMARILLO}Configurando Ngrok...${SIN_COLOR}"
    mkdir -p "$NGROK_CONFIG_DIR"
    chmod 700 "$NGROK_CONFIG_DIR"

    read -p "¿Deseas editar manualmente el archivo ngrok.yml para agregar tu token? (s/n) [s]: " respuesta
    respuesta=${respuesta:-s}

    if [[ "$respuesta" =~ ^[sS]$ ]]; then
        cat > "$NGROK_CONFIG_FILE" <<EOF
authtoken: REEMPLAZAR_CON_TU_TOKEN
version: "2"
tunnels:
  socks-proxy:
    addr: $SOCKS_PROXY_PORT
    proto: tcp
EOF
        echo -e "${CIA}Abriendo ngrok.yml para edición...${SIN_COLOR}"
        sleep 1
        nano "$NGROK_CONFIG_FILE"
    else
        read -p "Ingresa tu token de Ngrok: " authtoken
        while [[ -z "$authtoken" ]]; do
            echo -e "${ROJO}El token no puede estar vacío!${SIN_COLOR}"
            read -p "Ingresa tu token de Ngrok: " authtoken
        done
        cat > "$NGROK_CONFIG_FILE" <<EOF
authtoken: $authtoken
version: "2"
tunnels:
  socks-proxy:
    addr: $SOCKS_PROXY_PORT
    proto: tcp
EOF
    fi
}

configure_dante() {
    echo -e "${AMARILLO}Configurando servidor SOCKS...${SIN_COLOR}"
    default_interface=$(ip route | grep default | awk '{print $5}' | head -n1)
    [ -z "$default_interface" ] && default_interface="eth0"

    cat > /etc/danted.conf <<EOF
logoutput: syslog
internal: 0.0.0.0 port = $SOCKS_PROXY_PORT
external: $default_interface
method: username none
user.privileged: root
user.notprivileged: nobody
client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect error
}
pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    command: bind connect udpassociate
    log: connect disconnect error
}
EOF
}

setup_socks_service() {
    echo -e "${AMARILLO}Configurando servicio Ngrok SOCKS...${SIN_COLOR}"
    read -p "¿Qué región de Ngrok? (us, eu, ap, au, sa, jp, in) [us]: " region
    region=${region:-us}

    cat > $NGROK_SERVICE_FILE <<EOF
[Unit]
Description=Ngrok SOCKS5 Tunnel
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/ngrok start --config $NGROK_CONFIG_FILE --region=$region socks-proxy
Restart=always
RestartSec=3
User=root

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable --now $(basename $NGROK_SERVICE_FILE)
}

setup_dante_service() {
    echo -e "${AMARILLO}Configurando servicio Dante...${SIN_COLOR}"
    cat > $DANTE_SERVICE_FILE <<EOF
[Unit]
Description=Dante SOCKS5 daemon
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/danted -f /etc/danted.conf
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable --now danted.service
}

show_instructions() {
    echo -e "\n${VERDE}Configuración completada!${SIN_COLOR}"
    echo -e "Servicios activos:"
    echo -e "  - Ngrok: ${CIA}systemctl status ngrok-socks${SIN_COLOR}"
    echo -e "  - Dante: ${CIA}systemctl status danted${SIN_COLOR}"

    echo -e "\nPara probar conexión:"
    echo -e "   ${CIA}curl --socks5-hostname 127.0.0.1:$SOCKS_PROXY_PORT ifconfig.me${SIN_COLOR}"

    echo -e "\nConfigura Brave con flags:"
    echo -e "   brave-browser --proxy-server='socks5://127.0.0.1:$SOCKS_PROXY_PORT'"
}

main() {
    check_root
    install_dependencies
    configure_ngrok
    configure_dante
    setup_socks_service
    setup_dante_service
    show_instructions
}

main
