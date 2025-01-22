#!/bin/bash

# Variables del servidor remoto (victima)
remote_host='192.168.0.24'
remote_user='root'
remote_pass='almalinux'

# Rutas
local_path='/home/ubuntu/taller2/backups'
remote_path='/home/taller2/backups'

# Variables base de datos MySQL
mysql_user='root'
mysql_pass='taller2'
mysql_dbname='taller2'
mysql_dbuser='taller2'
mysql_dbpass='taller2-wordpress'

# Variables base de datos PostgreSQL
pg_user='postgres'
pg_pass='taller2-postgresql'
pg_dbname='taller2'
pg_dbuser='taller2'
pg_dbpass='taller2-postgres'

# Obtener fecha y hora actual
timestamp=$(date "+%Y%m%d_%H%M%S")

# Backup de tipo completo
echo 'Iniciando respaldo completo...'

	# Crea el directorio temporal de backups en la máquina remota si no existe
	sshpass -p $remote_pass ssh $remote_user@$remote_host "mkdir -p $remote_path"

	# Backup del CMS Wordpress
	sshpass -p $remote_pass ssh $remote_user@$remote_host "tar -czf $remote_path/wordpress_$timestamp.tar.gz -C /home/taller2/public_html/wordpress ."
	echo 'Respaldo completo del CMS Wordpress finalizado.'

	# Backup de la base de datos MySQL
	sshpass -p $remote_pass ssh $remote_user@$remote_host "mysqldump -u$mysql_user -p$mysql_pass $mysql_dbname > $remote_path/mysql_$timestamp.sql"
	echo 'Respaldo completo de MySQL finalizado.'

	# Backup de la base de datos PostgreSQL
	sshpass -p $remote_pass ssh $remote_user@$remote_host "PGPASSWORD=$pg_pass pg_dump -U $pg_user $pg_dbname > $remote_path/postgresql_$timestamp.sql"
	echo 'Respaldo completo de PostgreSQL finalizado.'

	# Comprimir los backups del CMS y bases de datos en un archivo tar
	sshpass -p $remote_pass ssh $remote_user@$remote_host "tar -czf $remote_path/backup_completo_$timestamp.tar.gz -C $remote_path wordpress_$timestamp.tar.gz mysql_$timestamp.sql postgresql_$timestamp.sql"
	echo 'Backups comprimidos correctamente.'

	# Enviar el backup completo al Ubuntu Server
	sshpass -p $remote_pass scp $remote_user@$remote_host:$remote_path/backup_completo_$timestamp.tar.gz $local_path/
	echo 'Backup completo ha sido enviado correctamente a Ubuntu Server.'

	# Verificar la integridad de los backups mediante sha256sum
	# Si los checksum del backup remoto y el backup en la máquina local coinciden, se verifica la integridad de los datos
	# Se utiliza awk para obtener el primer valor del resultado del comando sha256sum (el checksum correspondiente)
	echo "Verificando integridad de los backups..."
	remote_backup_checksum=$(sshpass -p $remote_pass ssh $remote_user@$remote_host "sha256sum $remote_path/backup_completo_$timestamp.tar.gz | awk '{print \$1}'")
	local_backup_checksum=$(sha256sum $local_path/backup_completo_$timestamp.tar.gz | awk '{print $1}')
	echo "Checksum local: $local_backup_checksum"
	echo "Checksum remoto: $remote_backup_checksum"

	if [ "$local_backup_checksum" == "$remote_backup_checksum" ]; then
		echo 'Integridad del backup completo varificada correctamente.'
	else
		echo 'Error: La integridad del backup completo es incorrecta, los checksum local y remoto no coinciden.'
	fi

	# Eliminar carpeta temporal "backups" en la máquina remota para no dejar evidencia
	sshpass -p $remote_pass ssh $remote_user@$remote_host "rm -rf $remote_path"
	echo 'Carpeta backups eliminada correctamente de la máquina remota'

	# Cifrar backup completo con GPG
	echo 'Seleccionar opción para cifrar el backup con GPG:'
	echo '1) Cifrado simétrico'
	echo '2) Cifrado asimétrico'
	echo '3) Firma digital'
	read option

	echo 'Seleccionaste la opción' $option

	if [[ $option -eq 1 ]]; then

		# Cifrado simétrico
		gpg --symmetric --cipher-algo AES256 $local_path/backup_completo_$timestamp.tar.gz
		echo 'El backup ha sido cifrado de forma simétrica correctamente.'
	
	elif [[ $option -eq 2 ]]; then

		# Cifrado asimétrico
		echo 'Ingresar clave pública para el cifrado asimétrico:'
		read public_key
		gpg --encrypt --recipient $public_key $local_path/backup_completo_$timestamp.tar.gz
		echo 'El backup ha sido cifrado de forma asimétrica correctamente.'

	elif [[ $option -eq 3 ]]; then

		# Firma digital
		gpg --detach-sign $local_path/backup_completo_$timestamp.tar.gz
		echo 'El backup ha sido firmado digitalmente.'

	fi

	# Eliminar archivo original para dejar solo el cifrado
	rm -rf $local_path/backup_completo_$timestamp.tar.gz
