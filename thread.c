#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <dirent.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <pthread.h>
#include <string.h>
#include <errno.h>

#define MAX_THREADS 100

// Structure pour stocker les informations nécessaires pour chaque thread
struct ThreadInfo {
    char source_path[PATH_MAX];
    char backup_directory[PATH_MAX];
};

// Fonction pour obtenir l'extension d'un fichier
const char *get_file_extension(const char *filename) {
    const char *dot = strrchr(filename, '.');
    if (!dot || dot == filename) return "";
    return dot + 1;
}

#define BUF_SIZE 4096

void copyFile(const char *source, const char *destination) {
    int source_fd, dest_fd;
    ssize_t bytes_read, bytes_written;
    char buffer[BUF_SIZE];

    // Ouvrir le fichier source
    source_fd = open(source, O_RDONLY);
    if (source_fd == -1) {
        perror("Erreur lors de l'ouverture du fichier source");
        exit(EXIT_FAILURE);
    }

    // Créer le fichier destination avec les droits du fichier source
    dest_fd = open(destination, O_CREAT | O_WRONLY | O_TRUNC, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH);
    if (dest_fd == -1) {
        perror("Erreur lors de la création du fichier destination");
        exit(EXIT_FAILURE);
    }

    // Copier le contenu
    while ((bytes_read = read(source_fd, buffer, BUF_SIZE)) > 0) {
        bytes_written = write(dest_fd, buffer, bytes_read);
        if (bytes_written != bytes_read) {
            perror("Erreur lors de l'écriture dans le fichier destination");
            exit(EXIT_FAILURE);
        }
    }

    // Fermer les fichiers
    if (close(source_fd) == -1 || close(dest_fd) == -1) {
        perror("Erreur lors de la fermeture des fichiers");
        exit(EXIT_FAILURE);
    }
}

void copyDirectory(const char *source, const char *destination) {
    DIR *dir;
    struct dirent *entry;
    struct stat statbuf;

    // Ouvrir le répertoire source
    dir = opendir(source);
    if (dir == NULL) {
        perror("Erreur lors de l'ouverture du répertoire source");
        exit(EXIT_FAILURE);
    }

    // Créer le répertoire destination
    if (mkdir(destination, 0777) == -1) {
        perror("Erreur lors de la création du répertoire destination");
        exit(EXIT_FAILURE);
    }

    // Parcourir les entrées du répertoire source
    while ((entry = readdir(dir)) != NULL) {
        char source_path[PATH_MAX];
        char dest_path[PATH_MAX];

        // Ignorer les entrées spéciales "." et ".."
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
            continue;
        }

        // Construire les chemins complets pour la source et la destination
        snprintf(source_path, sizeof(source_path), "%s/%s", source, entry->d_name);
        snprintf(dest_path, sizeof(dest_path), "%s/%s", destination, entry->d_name);

        // Obtenir les informations sur l'entrée
        if (lstat(source_path, &statbuf) == -1) {
            perror("Erreur lors de la récupération des informations sur l'entrée");
            exit(EXIT_FAILURE);
        }

        // Copier les fichiers ou les répertoires récursivement
        if (S_ISREG(statbuf.st_mode)) {
            copyFile(source_path, dest_path);
        } else if (S_ISDIR(statbuf.st_mode)) {
            copyDirectory(source_path, dest_path);
        }
    }

    // Fermer le répertoire
    closedir(dir);
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
    copyFile(source_path, dest_path) ;
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
    copyDirectory(source_directory, dest_path) ;
}


// Fonction exécutée par chaque thread
void *backup_thread(void *arg) {
    struct ThreadInfo *thread_info = (struct ThreadInfo *)arg;

    struct stat file_stat;
    if (lstat(thread_info->source_path, &file_stat) == -1) {
        perror("Error getting file status");
        pthread_exit(NULL);
    }

    if (S_ISDIR(file_stat.st_mode)) {
        copy_directory_with_date(thread_info->source_path, thread_info->backup_directory);
    } else {
        copy_file_with_date(thread_info->source_path, thread_info->backup_directory);
    }

    free(thread_info); // Libérer la mémoire allouée pour la structure ThreadInfo
    pthread_exit(NULL);
}

int main(int argc, char *argv[]) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s source_directory backup_directory\n", argv[0]);
        return 1;
    }

    char *source_directory = argv[1];
    char *backup_directory = argv[2];

    // Ouvrir le répertoire source
    DIR *dir = opendir(source_directory);
    if (dir == NULL) {
        perror("Error opening source directory");
        return 1;
    }

    struct dirent *entry;
    pthread_t threads[MAX_THREADS]; // Tableau pour stocker les identifiants de thread
    int thread_count = 0;

    // Parcourir les entrées du répertoire source
    while ((entry = readdir(dir)) != NULL) {
        // Ignorer les répertoires spéciaux "." et ".."
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
            continue;
        }

        // Chemin complet de l'élément
        char full_path[PATH_MAX];
        snprintf(full_path, PATH_MAX, "%s/%s", source_directory, entry->d_name);

        // Créer un thread pour sauvegarder l'élément
        struct ThreadInfo *thread_info = malloc(sizeof(struct ThreadInfo));
        if (thread_info == NULL) {
            perror("Error allocating memory");
            return 1;
        }
        strcpy(thread_info->source_path, full_path);
        strcpy(thread_info->backup_directory, backup_directory);

        if (pthread_create(&threads[thread_count], NULL, backup_thread, thread_info) != 0) {
            perror("Error creating thread");
            free(thread_info);
            return 1;
        }

        thread_count++;

        // Limiter le nombre de threads pour éviter la surcharge
        if (thread_count >= MAX_THREADS) {
            break;
        }
    }

    // Attendre la fin de tous les threads
    for (int i = 0; i < thread_count; i++) {
        pthread_join(threads[i], NULL);
    }

    closedir(dir);

    return 0;
}