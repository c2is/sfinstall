#!/bin/bash
read -p "Souhaitez-vous cloner un projet ici ? [y,N] " resp
if [ $resp != "y" ]; then 
	echo "Ok, ok, on oublie..."; 
else
		read -p "Url du repository (format ssh : git@github.com:c2is/XXX.git par exemple) : " giturl
		git clone $giturl clonetmp
		cd clonetmp
		mv .[!.]* ../
		mv * ../
		rm -rf clonetmp
fi