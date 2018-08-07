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


