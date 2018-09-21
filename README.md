# Symfony installer

## Usage
```sh
sfinstall [subdirectory]
```

## Description
Installe Symfony et optionnellement un environnement docker  

L'installation de Symfony fournit :
- un .gitignore adapté,
- un parameters.yml prêt à l'emploi avec docker,
- les fichiers *-at-preprod *-at-prod utilisés chez Acti.


L'environnement docker fournit :
- apache, php-fpm, mysql...
- un certificat ssl valide pour les domaines types *.dev.acti,
- un service mail utilisable en smtp ou directemnt via sendmail dans le container php.

Le composer est un container sans démon, il s'utilise donc ainsi :  
```sh
dc run composer composer --working-dir=/var/www/website
```
Bien mettre les commandes composer avant --working-dir, par exemple :  
`sh
dc run composer composer require google/apiclient:^2.0 --working-dir=/var/www/website
```

## Installation

#### Linux/Bsd
```sh
curl -skL https://raw.githubusercontent.com/c2is/sfinstall/master/sfinstall.sh --output /usr/local/bin/sfinstall; chmod +x /usr/local/bin/sfinstall;
```
#### Ubuntu
```sh
sudo curl -skL https://raw.githubusercontent.com/c2is/sfinstall/master/sfinstall.sh --output /usr/local/bin/sfinstall; sudo chmod +x /usr/local/bin/sfinstall;
```

#### Windows Mingw
```sh
mkdir ~/bin/; curl -skL https://raw.githubusercontent.com/c2is/sfinstall/master/sfinstall.sh --output ~/bin/sfinstall; chmod +x ~/bin/sfinstall;
```

### Update

#### Linux/Bsd
```sh
curl -skL https://raw.githubusercontent.com/c2is/sfinstall/master/sfinstall.sh --output /usr/local/bin/sfinstall;
```

#### Ubuntu
```sh
sudo curl -skL https://raw.githubusercontent.com/c2is/sfinstall/master/sfinstall.sh --output /usr/local/bin/sfinstall;
```

#### Windows Mingw
```sh
curl -skL https://raw.githubusercontent.com/c2is/sfinstall/master/sfinstall.sh --output ~/bin/sfinstall;
```
