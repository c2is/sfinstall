#/bin/bash
if [ "$(uname)" != "Linux" ]; then rpath=`readlink "$0"`; else rpath=`readlink -f "$0"`; fi;
abs_path=$(dirname "$rpath")



function echolor () {
	red="\033[31m"
	green='\033[32m'
	yellow='\033[33m'
	std="\033[0m"
	case $1 in
		r)
		  color=$red
		  ;;
		g)
		 color=$green
		  ;;
		y)
		  color=$yellow
		  ;;
		s)
		  color=$std
		  ;;

	esac

	echo -e $color$2$std
}

dir=$1
install_path=$(pwd)/$dir


if [ "$dir" == "" ]; then
	echolor r "Validation avant suppression des fichiers de $install_path" 
	read -p "Vous n'avez pas indiqué de répertoire d'installation, Symfony sera installé ici : "$install_path" ok [Y,n] : " yn
	if [[ ! $yn =~ ^[Yy]$ ]]
	then
	    echo "Ok, ok... on arrête tout."
	    exit 1
	fi
else
	if [ -d $dir ] || [ -f $dir ]; then echo "Ce répertoire existe déjà, on arrête tout."; exit 1; fi
	mkdir -p $dir
    cd $dir
fi

sudo_opt=""
read -p "Avez-vous besoin sudo ok [Y,n] : " yn
if [[ $yn =~ ^[Yy]$ ]]
then
    sudo_opt="sudo"
fi

cd $install_path;
rm -rf ..?* .[!.]* *


###########################
# INSTALL
###########################

function gitignore () {
	echolor y "Mise en place du gitignore dans "$install_path
	cat << EOF > $install_path"/.gitignore"
# Cache and logs (Symfony2)
/app/cache/*
/app/logs/*
!app/cache/.gitkeep
!app/logs/.gitkeep

# Email spool folder
/app/spool/*

# Cache, session files and logs (Symfony3)
/var/cache/*
/var/logs/*
/var/sessions/*
!var/cache/.gitkeep
!var/logs/.gitkeep
!var/sessions/.gitkeep

# Parameters
/app/config/parameters.yml
/app/config/parameters.ini

# Managed by Composer
/app/bootstrap.php.cache
/var/bootstrap.php.cache
/bin/*
!bin/console
!bin/symfony_requirements
/vendor/

# Assets and user uploads
/web/bundles/
/web/uploads/

# PHPUnit
/app/phpunit.xml
/phpunit.xml

# Build data
/build/

# Composer PHAR
/composer.phar

# Backup entities generated with doctrine:generate:entities command
**/Entity/*~

# Embedded web-server pid file
/.web-server-pid
EOF
}

function symfony4_install() {
	#docker-compose run composer composer create-project symfony/website-skeleton /var/www/website/
	$sudo_opt docker run --rm --interactive --tty --volume $PWD:/var/www/website composer create-project symfony/website-skeleton /var/www/website/
	echolor y "Mise en place des fichiers de configutations \"-at-preprod\" et \"-at-prod\""

}
function symfony_install() {
    $sudo_opt docker run --rm --interactive --tty --volume $PWD:/var/www/website composer create-project symfony/framework-standard-edition /var/www/website/ "2.8.*"
	cp $install_path"/app/config/parameters.yml.dist" $install_path"/app/config/parameters.yml-at-prod"
	cp $install_path"/app/config/parameters.yml.dist" $install_path"/app/config/parameters.yml-at-preprod"
}


echolor y "Récupération de Symfony dans "$install_path
symfony_install

gitignore




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
			if [ "$port" == "80" ]; then
				read -p "Voulez vous stopper les containers des autres projets tournant sur le port 80 ? [y,N] " resp
		    	if [ $resp == "y" ]; then docker stop $(docker ps |grep ":80->" | cut -d " " -f1); fi
			fi
		fi

		if [ "$(is_used $port)" == "y" ]; then
			newport=$(get_next_free_port $port)
			echo $port" est occupé, on le remplace par : "$newport
			perl -pi -e "s/\"$port:/\"$newport:/" docker-compose.yml
		fi
	done

	read -p "Domaine pour le vhost ?"$'\n' domain
	perl -pi -e "s/- WEBSITE_HOST=domain/- WEBSITE_HOST=$domain/" docker-compose.yml

	perl -pi -e "s/- CERTIFICAT_CNAME=domain/- CERTIFICAT_CNAME=$domain/" docker-compose.yml

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
	echo "Maintenant vous pouvez importer un dump mysql, par exemple :"
	echo ""
	echo "docker exec -i "$mysql_container"_db_1 mysql website < ./dump.sql"
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
    image: debian:jessie
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
    image: php:7.0.31-fpm-stretch
    volumes_from:
        - application
    links:
        - db
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
Changer les params dans wordpress (db host etc.)
COMMENT


echo "FINI"



