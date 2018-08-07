#/bin/bash
if [ "$(uname)" != "Linux" ]; then rpath=`readlink "$0"`; else rpath=`readlink -f "$0"`; fi;
abs_path=$(dirname "$rpath")

. $abs_path/helpers.sh

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

. $abs_path/install.sh
. $abs_path/docker.sh

echo -y "L'installation est terminé"



