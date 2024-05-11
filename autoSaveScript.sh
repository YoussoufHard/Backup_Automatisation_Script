#!/bin/bash

# Initialisation des variables pour les options
use_fork=false
use_thread=false
use_subshell=false
use_log=false
use_restore=false
log_dir="_"
# Fonction pour enregistrer les messages dans le fichier de journalisation
log_message() {
    local type=$1
    local message=$2
    local lld=$3
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
  # if [ $? -ne 0 ]; then
    echo "$timestamp : $username : $type : $message" >> "$log_dir/history.log"
   # fi
}

# Redirection des sorties standard et d'erreur vers le terminal et le fichier de journalisation

# Fonction d'affichage de l'aide
display_help() {
    echo "Usage: $0 NbHeure [options] source_directory backup_directory"
    echo "Options:"
    echo "  Sans option          Execution simple faire un backup (pour les admnistrateur)"
    echo "  -h, --help           Affiche l'aide"
    echo "  -f, --fork           Exécution par création de sous-processus avec fork"
    echo "  -t, --thread         Exécution par threads"
    echo "  -s, --subshell       Exécute le programme dans un sous-shell"
    echo "  -l, --log            Spécifie un répertoire pour le fichier de journalisation"
    echo "  -r, --restore        Réinitialise les paramètres par défaut (réservé aux administrateurs)"
    echo "                       Ce option met par defaut le nombre d'heure à 24heure et sans options)"
    echo "                       Ceci montre que si tu execute le script et que tu n'est pas un admnistrateur il faut obligatoirement donner le repertoire de log"

    echo "  Pour le bon fonctionnement de l'automatisation donner le chemin complet pour chaque argument "
    echo "il faut obligatoirement donner les deux options si tu specifie les options le nombre d'heures est optionnel "
}

# Nombre d'heures spécifié par l'utilisateur
if [[  "$1" =~ ^[0-9]+$ ]]; then
    heures="$1"
    shift  # Ignorer le premier argument (le nombre d'heures)
fi
# Arguments supplémentaires à passer au script
args=("$@")  # Stocker les arguments restants dans un tableau

# Chemin vers votre script à exécuter
ss=$0 
ss="${ss#./}"
script_path="\"$PWD/$ss\""
#echo "$script_path"
if [ -n "$heures" ]; then
    script_path+=" $heures"
fi
# Ajouter les arguments au chemin du script
for arg in "${args[@]}"; do
    script_path+=" \"$arg\""  # Encadrer chaque argument avec des guillemets simples pour éviter les problèmes avec les espaces
done
#echo "$script_path"


# Boucle pour traiter les options
while [[ $# -gt 2 ]]; do
    case $1 in
        -h | --help )
            display_help
            exit 0 # execution normal 
            ;;
        -f | --fork )
            use_fork=true
            ;;
        -t | --thread )
            use_thread=true
            ;;
        -s | --subshell )
            use_subshell=true
            ;;
        -l | --log )
            use_log=true
            shift
            log_dir=$1
           # echo "mmmmmmmmmm $1"
            ;;
        -r | --restore )
            use_restore=true
            ;;
        *)
            echo "Option non reconnue: $1"
            display_help
            exit 103 # argument inconue 
            ;;
    esac
    shift  # Passer à l'argument suivant
done

#on aura aussi ces deux ligne avant chaque execution ce qui pourra facilement etre utiliser comme une difference dans le logFile 
exec > >(tee >(log_message "INFOS") >&1)
exec 2> >(tee >(log_message "ERROR") >&2)

# Vérification du nombre d'arguments
if [ "$#" -lt 2 ]; then
    echo "Erreur : Le nombre d'arguments est insuffisant."
    display_help
    exit 101
fi

#verification de l'existance du repertoire source 

if [ ! -d "$1" ] ; then 
       log_message "ERROR" "Le répertoire source '$1' n'existe pas." "$log_dir"
    exit 100 
fi 

#verification de l'existance du repertoire de destination 

if [ ! -d "$2" ] ; then 
   log_message "ERROR" "Le répertoire de destination '$2' n'existe pas." "$log_dir"

    mkdir -p "$2"
 
    if [ $? -ne 0 ] ; then  # on verifie si le code de sortie de la creation du reperoire est egale à 0 c a success 
    log_message "Erreur" "lors de la creation du repertoire de destination '$2' ." "$log_dir"
        exit 102 ; # erreur de creation 
     else
        log_message "INFOS" "Répertoire de destination '$2' créé avec succès." "$log_dir"
    fi

fi 

# Backup Operation based on Options ==> operation basé sur les options 

if [ "$use_fork" = true ]; then
    # Backup using fork
    log_message "INFOS" "Execution avec fork(C)" "$log_dir"   # Your backup logic with fork
    ./fork "$1" "$2"
    log_message "INFOS" "Fin de l'Execution avec fork(C)" "$log_dir"   # Your backup logic with fork
fi
if [ "$use_thread" = true ]; then
    # Backup using threads
     log_message "INFOS" "Execution avec threads" "$log_dir"
     ./thread "$1" "$2"
     log_message "INFOS" "Fin de l'Execution avec threads" "$log_dir"
fi

if [ "$use_subshell" = true ]; then
    # Backup using subshell
    log_message "INFOS" "Execution avec un sous shell" "$log_dir"
    # Exécuter le script de sauvegarde dans un sous-shell
    (bash subshell.sh "$1" "$2" "$log_dir")
fi

#ici on renitialise les parmatre par defaut c'est à dire execution sans aucune option et le dossier dir par defaut aussi
if [ "$use_restore" = true ]; then
    # Vérifier si l'utilisateur est administrateur (root) ou membre du groupe sudo
    if [ "$(whoami)" != "root" ] && ! groups | grep -q '\bsudo\b'; then
        echo "Erreur : Seul l'administrateur ou les utilisateurs autorisés peuvent utiliser l'option de restauration des paramètres par défaut."
        log_message "Erreur " "Seul l'administrateur ou les utilisateurs autorisés peuvent utiliser l'option de restauration des paramètres par défaut." "$log_dir"
        exit 1
    fi

    # Restauration des paramètres par défaut
    log_message "INFOS" "Restauration des paramètres par défaut." "$log_dir"
    
    #il faut juste appelé le programme lui meme avec sans option et le nombre d'heure par defaut est 24h
    ./autoSaveScript.sh "24" "$1" "$2" 
fi


 #avant de commencer il faut d'abord verifier ou specifier le logdir
if  [ "$use_log" = true ]; then
    # Backup using log
    log_message "INFOS" "Execution en utilisant un fichier de journalisation" "$log_dir"
fi 

if ! $use_fork && ! $use_thread && ! $use_subshell && ! $use_restore; then   
#     echo -n "Execution normal" 
#     sleep 1 
#     echo -n "."
#     sleep 1 
#     echo  -n "."
#     sleep 1
#     echo "."

#    echo "Copie des fichiers " 
if [ "$(whoami)" != "root" ] && ! groups | grep -q '\bsudo\b'; then
     echo "Erreur : Seul l'administrateur ou les utilisateurs autorisés peuvent utiliser des paramètres par défaut sans option."
   exit 104 #pas acces 
fi
    log_message "INFOS" "Execution normal" "$log_dir" 
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

fi



#Ajout du script avec ses arguments dans le crontab pour l'execution automatique chaque NbHeures 

# Étape 1 : Créer un fichier temporaire contenant la configuration cron
cron_config=$(mktemp)

echo "0 */$heures * * * $script_path" >> "$cron_config"

# Étape 2 : Ajouter la configuration cron à la crontab
crontab "$cron_config"

# Étape 3 : Nettoyer le fichier temporaire
rm "$cron_config"

echo "La tâche cron pour exécuter '$script_path' toutes les $heures heures a été configurée."
