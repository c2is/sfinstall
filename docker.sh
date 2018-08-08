#!/bin/bash
function dockerize () {
	port="[0-9]"
	if [ -f docker-compose.yml ]; then

		read -p "Le fichier docker-compose.yml existe déjà, on l'écrase ? [y,N] " resp
		if [ $resp != "y" ]; then echo "Ok..."; return 0; fi
		echo "Arrêts des containers de cet environnement..."
		docker-compose stop
	fi

	docker_compose_write

	ports_wanted=$(grep -A3 "ports" docker-compose.yml | grep "[0-9]" | cut -c12-25 | sed 's/"//' | cut -d':' -f1)

	for port in $ports_wanted; do
		if [ "$(is_used $port)" == "y" ]; then
			if [ "$port" == "80" ] || [ "$port" == "443" ]; then
				read -p "Voulez-vous stopper les containers des autres projets tournant sur le port 80 ? [y,N] " resp
		    	if [ $resp == "y" ]; then docker stop $(docker ps |grep ":80->" | cut -d " " -f1); fi
			fi
		fi

		if [ "$(is_used $port)" == "y" ]; then
			newport=$(get_next_free_port $port)
			echo $port" est occupé, on le remplace par : "$newport
			perl -pi -e "s/\"$port:/\"$newport:/" docker-compose.yml
		fi
	done

	read -p "Domaine pour le vhost (s'il se finit par dev.acti vous aurez un certificat ssl valide) : "$'\n' domain
	perl -pi -e "s/- WEBSITE_HOST=unprojet.dev.acti/- WEBSITE_HOST=$domain/" docker-compose.yml

	perl -pi -e "s/- CERTIFICAT_CNAME=unprojet.dev.acti/- CERTIFICAT_CNAME=$domain/" docker-compose.yml

	perl -pi -e "s/- maildomain=unprojet.dev.acti/- maildomain=$domain/" docker-compose.yml

	read -p "Voulez-vous ajouter la ligne \"127.0.0.1 $domain\" à votre fichier hosts ? [y,N] " resp
	if [ $resp != "y" ]; then 
		echo "Ok, ok, on touche pas au fichier hosts..."; 
	else
		host_file="/etc/hosts"
		(sudo echo "127.0.0.1 $domain" && sudo cat $host_file) > temp && sudo mv temp $host_file
	fi
	echo '""""""""""""""""'
	echo -e "Démarrage des containers...\n"

	docker-compose up -d
	if [ "$?" -ne 0 ]; then return 0; fi

	mysql_container=`basename $(pwd) | sed "s/_//g"`
	echo '""""""""""""""""'
	echolor g "Maintenant vous pouvez importer un dump mysql, par exemple :"
	echo ""
	echolor g "docker exec -i "$mysql_container"_db_1 mysql website < ./dump.sql"
}




function is_used() {
	if [ "$(uname)" == "Darwin" ]; then
		port_used=`netstat -anv | awk 'NR>2{print $4}' | grep -E '\.'$port | sed 's/.*\.//' | sort -n | uniq`
	else
		port_used=`netstat -lnt | awk 'NR>2{print $4}' | grep -E '0.0.0.0:$port' | sed 's/.*://' | sort -n | uniq`
	fi

	port=$1
	res="n"
	for i in ${port_used[@]}
	do
		if [ "$i" == ${port} ]; then
	    	res="y"; break;
	    fi
	done
	echo $res
}


function get_next_free_port() {
	port=$1

	#si le dernier chiffre est 0, on le retire
	if [ "${port:(${#port}-1):1}" == "0" ]; then
		port=$(echo $port | sed 's/.$//')
	fi
	limit="10000"
	counter=1
	while [  $counter -lt $limit ]; do
             newport=$port"$counter"
             if [ "$(is_used $newport)" == "n" ]; then
             	break;
             fi
             
        let counter=counter+1
    done

    echo $newport
	
}

function docker_compose_write () {
	cat << EOF > $install_path/docker-compose.yml
application:
    image: debian:stretch
    volumes:
        - ./:/var/www/website
    tty: true
db:
    image: mysql
    ports:
        - "3306:3306"
    environment:
        MYSQL_DATABASE: website
        MYSQL_ALLOW_EMPTY_PASSWORD: "yes"
php:
    image: c2is/debian-php
    volumes_from:
        - application
    links:
        - db
        - mail
composer:
    image: composer
    volumes_from:
        - application
    links:
        - db
apache:
    image: c2is/debian-apache
    environment:
        - WEBSITE_HOST=unprojet.dev.acti
        - CERTIFICAT_CNAME=unprojet.dev.acti
        - SYMFONY_VHOST_COMPLIANT=yes
    ports:
        - "80:80"
        - "443:443"
    links:
        - php
    volumes_from:
        - application
mail:
    image: catatnight/postfix
    environment:
        - maildomain=unprojet.dev.acti
        - smtp_user=web:web
    ports:
        - "25"
EOF

}

dockerhere=$(docker)
if [ "$?" -ne 0 ]; 
	then 
		echolor y  "Docker n'est pas installé sur votre machine : ce script ne mettera pas en place l'environnement docker."; 
	else
		echolor y  "Docker est installé, mise en place de l'environnement docker du projet"; 
		dockerize
fi

: <<'COMMENT'
TODO

COMMENT
