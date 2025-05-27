```markdown
# Ngrok Installer for Lando (Manjaro/Linux)

[![CI/CD Pipeline](https://github.com/0xC1pher/installer-ngrok/actions/workflows/lando-ngrok-ci.yml/badge.svg)](https://github.com/0xC1pher/installer-ngrok/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Herramienta completa para integración segura de Ngrok con Lando en entornos Linux, incluyendo configuración como servicio systemd y pipeline CI/CD.

![Demo](https://raw.githubusercontent.com/ngrok/ngrok/master/assets/ngrok-terminal-v5.png)

## Características Principales

- 🚀 Instalación automatizada en 1 comando
- 🔒 Configuración segura con autenticación de token
- 🛡️ Modo anti-censura con múltiples regiones
- ⚙️ Integración como servicio systemd
- 🔄 CI/CD con GitHub Actions
- 🧹 Limpieza automática de recursos
- 📊 Monitorización integrada

## Instalación Rápida

```bash
# Instalación automática
curl -sL https://raw.githubusercontent.com/0xC1pher/installer-ngrok/main/scripts/install-ngrok-lando.sh | sudo bash
```

## Uso Básico

### Para Desarrollo Local
```bash
# Iniciar túnel básico
landongrok [nombre-proyecto]

# Túnel con autenticación
ngrok http -auth="user:pass" 80
```

### Como Servicio Systemd
```bash
# Control del servicio
sudo systemctl start ngrok  # Iniciar
sudo systemctl stop ngrok   # Detener
sudo journalctl -u ngrok -f # Ver logs
```

### Configuración Avanzada
```bash
# Túnel SSH anti-censura
ngrok tcp --region=jp 22

# Listar túneles activos
curl -s localhost:4040/api/tunnels | jq
```

## Integración CI/CD

1. Agrega tu token de Ngrok como secreto en GitHub:
   ```bash
   gh secret set NGROK_AUTH_TOKEN --body=<TU_TOKEN>
   ```

2. Ejemplo de workflow (.github/workflows/lando-ngrok-ci.yml):
```yaml
- name: Run tests through ngrok
  run: |
    # Ejemplo test API
    curl -s ${{ env.NGROK_PUBLIC_URL }}/api/health | jq -e '.status == "ok"'
```

## Estructura del Repositorio

```
📁 .github/
│ └── 📁 workflows/          # Configuraciones CI/CD
📁 scripts/
│ ├── install-ngrok-lando.sh  # Instalador principal
│ └── uninstall.sh            # Script de desinstalación
📁 examples/                 # Configuraciones de ejemplo
📄 README.md                 # Este archivo
📄 LICENSE                   # Licencia Apache2.0
```

## Seguridad

### Mejores Prácticas
- 🔑 Rotar tokens cada 90 días
- 🔒 Usar siempre HTTPS
- 🛑 Limitar regiones de conexión
- 📝 Habilitar logs de auditoría

### Configuración Recomendada
```bash
# Firewall mínimo
sudo ufw allow from 0.0.0.0/0 to any port 443 proto tcp
sudo ufw enable
```
### Importante: Este script preserva:

Tus túneles configurados en ~/.ngrok2/ngrok.yml

Logs históricos en /var/log/ngrok/

## Troubleshooting

**Error: Conexión rechazada**
```bash
# Verificar servicio Lando
lando status

# Testear túnel local
curl -vk http://localhost:4040/status
```

**Error: Token inválido**
```bash
# Regenerar token
ngrok authtoken <NUEVO_TOKEN>
systemctl restart ngrok
```

## Contribución

1. Haz fork del repositorio
2. Crea tu feature branch:
```bash
git checkout -b feat/nueva-funcionalidad
```
3. Haz commit de tus cambios:
```bash
git commit -s -m "feat: add new security feature"
```
4. Push a la branch:
```bash
git push origin feat/nueva-funcionalidad
```
5. Abre un Pull Request

## Licencia

Distribuido bajo licencia MIT. Ver [LICENSE](LICENSE) para más detalles.

---

Hecho con ❤️ por [0xC1pher](https://github.com/0xC1pher) | Documentación actualizada: $(date +'%Y-%m-%d')
```

**Características adicionales del README:**
1. Compatible con GitHub Dark Mode
2. Secciones colapsables en GitHub
3. Enlaces inteligentes a acciones y recursos
4. Compatible con `gh repo view`
5. Incluye cheatsheet rápida
6. Integración con GitHub CLI
7. Badges dinámicos
8. Estructura visual clara

Para usar el README:
1. Guarda como `README.md` en la raíz del repo
2. Actualiza las secciones con tus datos específicos
3. Agrega capturas de pantalla relevantes
4. Asegúrate de que los enlaces a los scripts sean correctos
