#!/bin/bash

# Colores para mensajes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Verificar root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Este script debe ejecutarse como root!${NC}"
        exit 1
    fi
}

# Desinstalar componentes principales
remove_components() {
    echo -e "${YELLOW}>>> Deteniendo y eliminando el servicio${NC}"
    systemctl stop ngrok.service 2>/dev/null
    systemctl disable ngrok.service 2>/dev/null
    rm -f /etc/systemd/system/ngrok.service
    systemctl daemon-reload
    
    echo -e "${YELLOW}>>> Eliminando archivos binarios${NC}"
    rm -f /usr/local/bin/ngrok
    rm -f /usr/local/bin/ngrok-start
    rm -f /usr/local/bin/ngrok-stop
    
    echo -e "${YELLOW}>>> Eliminando configuraciones${NC}"
    rm -rf $HOME/.config/ngrok
    rm -rf $HOME/.ngrok2
    
    echo -e "${YELLOW}>>> Eliminando alias${NC}"
    sed -i '/landongrok/d' $HOME/.bashrc
    sed -i '/landongrok/d' $HOME/.zshrc 2>/dev/null
}

# Limpiar dependencias
clean_dependencies() {
    echo -e "${YELLOW}>>> Limpiando paquetes temporales${NC}"
    rm -f /tmp/ngrok.zip
}

# Verificar desinstalación
verify_uninstall() {
    if ! command -v ngrok &> /dev/null && 
       [ ! -f /etc/systemd/system/ngrok.service ] && 
       [ ! -d $HOME/.config/ngrok ]; then
        echo -e "${GREEN}✓ Desinstalación completada con éxito!${NC}"
    else
        echo -e "${RED}⚠️ Algunos componentes no se pudieron remover completamente${NC}"
        exit 1
    fi
}

# Función principal
main() {
    check_root
    echo -e "\n${RED}=== DESINSTALADOR NGrok ===${NC}\n"
    
    remove_components
    clean_dependencies
    verify_uninstall
    
    echo -e "\n${YELLOW}Reinicia tu terminal para completar la desinstalación${NC}"
}

# Ejecutar
main
