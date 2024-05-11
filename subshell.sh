#!/bin/bash

log_dir="$3"
# Fonction pour enregistrer les messages dans le fichier de journalisation
log_message() {
    local type=$1
    local message=$2
   # echo "contenu de log dir $log_dir"
    if [ "$log_dir" = "_" ]; then
        log_dir="/var/log/autoSaveScript"
     
        #    echo "contenu de log dir $log_dir  mkm"    
    fi
       if [ "$log_dir" = "/var/log/autoSaveScript" ] && [ ! -d "$log_dir" ] ; then 
         echo "Tu es un admnistrateur sudoers mais pas le root donne le mot de passe root pour creer le log"
         sudo  mkdir -p "$log_dir" 2>/dev/null
         fi
      if [ ! -e "$log_dir/history.log" ] && [ "$log_dir" ="/var/log/autoSaveScript" ]; then
      sudo touch "$log_dir/history.log" 2>/dev/null
      fi
    #si le repertoire de log n'existe pas on le creer 
     # echo "contenu de log dir $log_dir  mkm"    
    if [ ! -d "$log_dir" ] ; then 
        mkdir -p "$log_dir" 2>/dev/null
        #    echo "contenu de log dir $log_dir  mkm"    
    fi
    if [ ! -e "$log_dir/history.log" ]; then
        touch "$log_dir/history.log" 2>/dev/null
    fi
   
    # echo "contenu de log dir $log_dir"
    local timestamp=$(date +"%Y-%m-%d-%H-%M-%S")
    local username=$(whoami)
   if [ $? -ne 0 ]; then
    echo "$timestamp : $username : $type : $message" >> "$log_dir/history.log"
    fi
}
   log_message "INFOS" "Copie des fichiers" "$log_dir"
    for file in "$1"/* ; do 
    # Ajouter un timestamp au nom du fichier pour le différencier
        timestamp=$(date +"%Y-%m-%d_%H-%M-%S")

        if [ -d "$file" ] ; then
            cp -r "$file" "$2/$(basename "$file")_$timestamp" 
         log_message "INFOS" "Dossier '$file' copié avec succès." "$log_dir"
        else  # si c'est un fichier 

            #Extraire l'extension du fichier ou utilsation de basename
            extension="${file##*.}"   
            
            # contaténer le nom de l'extension avec "files"
            dossier="${extension}Files"
            #creer le repertoire de destination pour cette extension si il n'existe pas encore
            if [ ! -d "$2/$dossier" ] ; then
            mkdir -p "$2/$dossier"
            fi
    
        #deplacer le fichier vers le repertoire correspondant à son extension
            cp "$file" "$2/$dossier/$(basename "$file")_$timestamp"
        log_message "INFOS" "Fichier '$file' copié avec succès." "$log_dir"
    fi
    done
