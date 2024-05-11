#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <dirent.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <string.h>
#include <limits.h>
#include <time.h>

// Fonction pour obtenir l'extension d'un fichier
const char *get_file_extension(const char *filename) {
    const char *dot = strrchr(filename, '.');
    if (!dot || dot == filename) return "";
    return dot + 1;
}

// Fonction pour copier un fichier avec une date et regrouper par extension
void copy_file_with_date(const char *source_path, const char *backup_directory) {
    // Obtenir l'extension du fichier
    const char *extension = get_file_extension(source_path);

    // Créer le répertoire de sauvegarde pour l'extension si nécessaire
    char backup_subdir[PATH_MAX];
    snprintf(backup_subdir, PATH_MAX, "%s/%sFile", backup_directory, extension);
    mkdir(backup_subdir, 0777);

    // Obtenir la date et l'heure actuelles
    time_t current_time;
    struct tm *time_info;
    char time_str[20];
    time(&current_time);
    time_info = localtime(&current_time);
    strftime(time_str, sizeof(time_str), "%Y-%m-%d-%H-%M-%S", time_info);

    // Nouveau nom de sauvegarde avec date et heure
    char new_name[PATH_MAX];
    snprintf(new_name, PATH_MAX, "%s_%s", source_path, time_str);

   // Chemin complet du fichier de destination avec le nouveau nom
    char dest_path[PATH_MAX];
    sprintf(dest_path, "%s/%s_%s", backup_subdir, strrchr(source_path, '/') + 1, time_str);

    // Copier le fichier vers le dossier de sauvegarde
    if (execlp("cp", "cp", source_path, dest_path, (char *)NULL) == -1) {
        perror("Error executing cp command");
        exit(1);
    }
}

// Fonction pour copier un répertoire avec une date
void copy_directory_with_date(const char *source_directory, const char *backup_directory) {
    // Obtenir le nom du répertoire
    const char *dir_name = strrchr(source_directory, '/');
    if (!dir_name) {
        dir_name = source_directory;
    } else {
        dir_name++; // Passer le caractère '/'
    }

    // Obtenir la date et l'heure actuelles
    time_t current_time;
    struct tm *time_info;
    char time_str[20];
    time(&current_time);
    time_info = localtime(&current_time);
    strftime(time_str, sizeof(time_str), "%Y-%m-%d-%H-%M-%S", time_info);

    // Nouveau nom de sauvegarde avec date et heure
    char new_name[PATH_MAX];
    snprintf(new_name, PATH_MAX, "%s_%s", dir_name, time_str);

    // Chemin complet du répertoire de destination
    char dest_path[PATH_MAX];
    sprintf(dest_path, "%s/%s", backup_directory, new_name);

    // Copier le répertoire vers le dossier de sauvegarde
    if (execlp("cp", "cp", "-r", source_directory, dest_path, (char *)NULL) == -1) {
        perror("Error executing cp command");
        exit(1);
    }
}

int main(int argc, char *argv[]) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s source_directory backup_directory\n", argv[0]);
        return 1;
    }

    char *source_directory = argv[1];
    char *backup_directory = argv[2];

    // Boucle pour lancer un processus fils pour chaque élément à sauvegarder
    DIR *dir = opendir(source_directory);
    if (dir == NULL) {
        perror("Error opening source directory");
        return 1;
    }

    struct dirent *entry;
    while ((entry = readdir(dir)) != NULL) {
        // Ignorer les répertoires spéciaux "." et ".."
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
            continue;
        }

        // Chemin complet de l'élément
        char full_path[PATH_MAX];
        snprintf(full_path, PATH_MAX, "%s/%s", source_directory, entry->d_name);

        // Obtenir les informations sur l'élément
        struct stat file_stat;
        if (lstat(full_path, &file_stat) == -1) {
            perror("Error getting file status");
            continue;
        }

        // Si c'est un répertoire
        if (S_ISDIR(file_stat.st_mode)) {
            pid_t pid = fork();
            if (pid == -1) {
                perror("Error forking process");
                return 1;
            } else if (pid == 0) {
                // Processus enfant : effectuer la sauvegarde du répertoire avec date
                copy_directory_with_date(full_path, backup_directory);
            }
        } else {
            // Si c'est un fichier
            pid_t pid = fork();
            if (pid == -1) {
                perror("Error forking process");
                return 1;
            } else if (pid == 0) {
                // Processus enfant : effectuer la sauvegarde du fichier avec date
                copy_file_with_date(full_path, backup_directory);
            }
        }
    }

    // Attendre la fin de tous les processus fils
    int status;
    pid_t wpid;
    while ((wpid = wait(&status)) > 0);

    closedir(dir);

    return 0;
}