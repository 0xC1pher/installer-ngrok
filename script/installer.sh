#!/bin/bash

# Colores para mensajes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

NGROK_SERVICE_FILE="/etc/systemd/system/ngrok.service"
CONFIG_DIR="$HOME/.config/ngrok"

# Verificar root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Ejecuta el script con sudo para configuración de sistema${NC}"
        exit 1
    fi
}

# Obtener token automáticamente
get_token_web() {
    echo -e "${CYAN}Abriendo panel de ngrok para obtener token...${NC}"
    xdg-open "https://dashboard.ngrok.com/get-started/your-authtoken" &> /dev/null
    
    read -p "Pega tu token de autenticación aquí: " token
    while [[ ! $token =~ ^[a-zA-Z0-9_\-]{32,48}$ ]]; do
        echo -e "${RED}Token inválido! Intenta nuevamente:${NC}"
        read -p "Token: " token
    done
    echo "$token"
}

# Configurar servicio systemd
setup_system_service() {
    echo -e "${YELLOW}>>> Creando servicio systemd${NC}"
    cat << EOF > $NGROK_SERVICE_FILE
[Unit]
Description=Ngrok Secure Tunnel Service
After=network.target

[Service]
Type=simple
User=$SUDO_USER
ExecStart=/usr/local/bin/ngrok tcp --log=stdout --region=us 22
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable ngrok.service
    echo -e "${GREEN}✓ Servicio creado!${NC}"
    echo -e "Usa: ${CYAN}systemctl start|stop|status ngrok${NC}"
}

# Configurar comandos personalizados
setup_commands() {
    echo -e "${YELLOW}>>> Creando accesos directos${NC}"
    cat << EOF > /usr/local/bin/ngrok-start
#!/bin/bash
sudo systemctl start ngrok
EOF

    cat << EOF > /usr/local/bin/ngrok-stop
#!/bin/bash
sudo systemctl stop ngrok
EOF

    chmod +x /usr/local/bin/ngrok-*
    echo -e "${GREEN}✓ Comandos creados:${NC}"
    echo -e "Iniciar: ${CYAN}ngrok-start${NC}"
    echo -e "Detener: ${CYAN}ngrok-stop${NC}"
}

# Configuración principal
main_config() {
    echo -e "\n${GREEN}=== Configuración Avanzada Ngrok ===${NC}"
    
    check_root
    token=$(get_token_web)
    
    echo -e "${YELLOW}>>> Configurando token${NC}"
    sudo -u $SUDO_USER ngrok authtoken $token
    
    setup_system_service
    setup_commands
    
    echo -e "\n${GREEN}Configuración completada!${NC}"
    echo -e "Modifica el servicio en: ${CYAN}$NGROK_SERVICE_FILE${NC}"
    echo -e "Registro de actividad: ${CYAN}journalctl -u ngrok.service -f${NC}"
}

# Menú de instalación
main_menu() {
    echo -e "${GREEN}=== Instalador Ngrok Anti-Censura ===${NC}"
    echo -e "1. Instalar y configurar completo (recomendado)"
    echo -e "2. Solo servicio systemd"
    echo -e "3. Desinstalar"
    echo -e "4. Salir"
    
    read -p "Selecciona una opción: " choice
    
    case $choice in
        1) main_config ;;
        2) setup_system_service ;;
        3) desinstalar ;;
        4) exit 0 ;;
        *) echo -e "${RED}Opción inválida!${NC}"; main_menu ;;
    esac
}

# Desinstalar
desinstalar() {
    check_root
    echo -e "${YELLOW}>>> Eliminando componentes...${NC}"
    systemctl stop ngrok.service
    systemctl disable ngrok.service
    rm -f $NGROK_SERVICE_FILE
    rm -f /usr/local/bin/ngrok*
    rm -f /usr/local/bin/ngrok
    rm -rf $CONFIG_DIR
    echo -e "${GREEN}✓ Ngrok desinstalado completamente!${NC}"
}

# Iniciar
main_menu
