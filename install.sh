#!/bin/bash
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
	$sudo_opt docker run --rm --interactive --tty --volume $PWD:/var/www/website composer create-project symfony/website-skeleton /var/www/website/ $version


}
function symfony_install() {
    $sudo_opt docker run --rm --interactive --tty --volume $PWD:/var/www/website composer -n create-project symfony/framework-standard-edition /var/www/website/ $version
	echolor y "Mise en place des fichiers de configutations"

	cat << EOF > $install_path/app/config/parameters.yml
parameters:
    database_host: db
    database_port: null
    database_name: website
    database_user: root
    database_password: root
    # utilise sendmail dans le container php, sendmail étant en fait un ssmtp utilisant le container "mail"
    mailer_transport: mail
    mailer_host: ~
    mailer_user: ~
    mailer_password: ~
    # possible d'utiliser le container "mail" directement en smtp :
    # mailer_transport: smtp
    # mailer_host: mail
    # mailer_user: web
    # mailer_password: web
    secret: ThisTokenIsNotSoSecretChangeIt
EOF
	cp $install_path"/app/config/parameters.yml.dist" $install_path"/app/config/parameters.yml-at-prod"
	cp $install_path"/app/config/parameters.yml.dist" $install_path"/app/config/parameters.yml-at-preprod"
}

versions=("2.8.*" "3.4.*" "4.1.*")
echo "Liste des versions installables :"
PS3="Choix de la version : "
select opt in ${versions[@]}
do
  version=$opt
  break
done

echolor y "Récupération de Symfony dans "$install_path
if [[ "$version" =~ ^4 ]]; then
	symfony4_install
else
	symfony_install
fi

gitignore


