#!/bin/bash

# Initialisation des variables pour les options
use_fork=false
use_thread=false
use_subshell=false
use_log=false
use_restore=false
log_dir="" 

# Fonction d'affichage de l'aide
display_help() {
    echo "Usage: $0 NbHeure [options] source_directory backup_directory"
    echo "Options:"
    echo "  Sans option          Execution simple faire un backup"
    echo "  -h, --help           Affiche l'aide"
    echo "  -f, --fork           Exécution par création de sous-processus avec fork"
    echo "  -t, --thread         Exécution par threads"
    echo "  -s, --subshell       Exécute le programme dans un sous-shell"
    echo "  -l, --log            Spécifie un répertoire pour le fichier de journalisation"
    echo "  -r, --restore        Réinitialise les paramètres par défaut (réservé aux administrateurs)"

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


# Vérification du nombre d'arguments
if [ "$#" -lt 2 ]; then
    echo "Erreur : Le nombre d'arguments est insuffisant."
    display_help
    exit 101
fi

#verification de l'existance du repertoire source 

if [ ! -d "$1" ] ; then 
    echo "Le répertoire source '$1' n'existe pas."
    exit 100 
fi 

#verification de l'existance du repertoire de destination 

if [ ! -d "$2" ] ; then 
    echo "Le répertoire de destination '$2' n'existe pas."

    mkdir -p "$2"
 
    if [ $? -ne 0 ] ; then  # on verifie si le code de sortie de la creation du reperoire est egale à 0 c a success 
        echo "Erreur lors de la creation du repertoire de destination '$2' ."
        exit 102 ; # erreur de creation 
     else
        echo "Répertoire de destination '$2' créé avec succès. "
    fi

fi 

# Backup Operation based on Options ==> operation basé sur les options 

if [ "$use_fork" = true ]; then
    # Backup using fork
    echo "Execution avec fork"
    # Your backup logic with fork
fi
if [ "$use_thread" = true ]; then
    # Backup using threads
    echo "Execution avec threads"
    # Your backup logic with threads
fi
if [ "$use_subshell" = true ]; then
    # Backup using subshell
    echo "Execution avec un sous shell"
    # Your backup logic with subshell
fi
if  [ "$use_log" = true ]; then
    # Backup using log
    echo "Execution en utilisant un fichier de journalisation"
    if [ ! -d "$log_dir" ] ; then 
        echo "Le répertoire de journalisation '$log_dir' n'existe pas."

        mkdir -p "$log_dir"
    
        if [ $? -ne 0 ] ; then  # on verifie si le code de sortie de la creation du reperoire est egale à 0 c a success 
            echo "Erreur lors de la creation du repertoire de journalisation '$log_dir' ."
            exit 102 ; # erreur de creation 
        else
            echo "Répertoire de journalisation '$log_dir' créé avec succès. "
        fi
    fi 
    # Your backup logic with subshell
 fi
 if [ "$use_restore" = true ]; then
    # Backup using restore
    echo "Restaurer les parametre par defaut: Execution avec Restore. "
    # Your backup logic with subshell
 fi
 
if ! $use_fork && ! $use_thread && ! $use_subshell && ! $use_log && ! $use_restore; then   
    echo -n "Execution normal" 
    sleep 1 
    echo -n "."
    sleep 1 
    echo  -n "."
    sleep 1
    echo "."

   echo "Copie des fichiers " 

    for file in "$1"/* ; do 
    # Ajouter un timestamp au nom du fichier pour le différencier
        timestamp=$(date +"%Y-%m-%d_%H-%M-%S")

        if [ -d "$file" ] ; then
            cp -r "$file" "$2/$(basename "$file")_$timestamp" 
        echo "Dossier '$file' copié avec succès ."
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
        echo "Fichier '$file' copié avec succès ."
    fi
    done

fi



#Ajout du script avec ses arguments dans le crontab pour l'execution automatique chaque NbHeures 

# Étape 1 : Créer un fichier temporaire contenant la configuration cron
cron_config=$(mktemp)
# Sauvegarder le contenu actuel du crontab dans un fichier temporaire
crontab -l > "$cron_config"
echo "0 */$heures * * * $script_path" >> "$cron_config"

# Étape 2 : Ajouter la configuration cron à la crontab
crontab "$cron_config"

# Étape 3 : Nettoyer le fichier temporaire
rm "$cron_config"

echo "La tâche cron pour exécuter '$script_path' toutes les $heures heures a été configurée."
