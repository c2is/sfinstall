# Symfony installer

## Usage
```sh
sfinstall [subdirectory]
```

## Description
Installe Symfony et optionnellement un environnement docker 
L'environnement docker fourni :
- apach, php-fpm, mysql...
- un certificat ssl valide pour les domaines types *.dev.acti
- un service mail utilisable en smtp ou directemnt via sendmail dans le container php

## Installation

#### Linux/Bsd
```sh
curl -skL https://raw.githubusercontent.com/c2is/sfinstall/master/sfinstall.sh --output /usr/local/bin/sfinstall; chmod +x /usr/local/bin/sfinstall;
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

#### Windows Mingw
```sh
curl -skL https://raw.githubusercontent.com/c2is/sfinstall/master/sfinstall.sh --output ~/bin/sfinstall;
```
