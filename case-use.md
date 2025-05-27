# Para evadir censura (ejemplo SSH):
sudo ngrok-start
sudo ngrok tcp --region=jp 22

# Para desarrollo web:
ngrok http -region=eu 80

# Monitorear tráfico:
ngrok http -log=stdout 80


##auth
 ngrok http -auth="usuario:contraseña" 80

## configuracion 
sudo systemctl edit ngrok.service
# Modificar parámetros y reiniciar
sudo systemctl restart ngrok
