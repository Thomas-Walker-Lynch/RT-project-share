#include <string.h>
#include <stdbool.h>

static bool is_authored_fs_obj(const char *path) {
    if (!path || strlen(path) == 0) {
        return false;
    }

    // Check if the last character is the pencil
    size_t len = strlen(path);
    return path[len - 1] == '🖉';
}


#include <stdlib.h>
#include <libgen.h>
#include <stdbool.h>
#include <string.h>

static bool is_authored(const char *path) {
    if (!path || strlen(path) == 0) {
        return false;
    }

    // Check the path itself
    if (is_authored_fs_obj(path)) {
        return true;
    }

    // Check each parent directory up to the root
    char *path_copy = strdup(path);
    if (!path_copy) {
        return false; // Memory allocation failure
    }

    char *parent = path_copy;
    bool authored = false;

    while (true) {
        parent = dirname(parent);

        // Check if the current directory is authored
        if (is_authored_fs_obj(parent)) {
            authored = true;
            break;
        }

        // If we reach the root, stop
        if (strcmp(parent, "/") == 0) {
            break;
        }
    }

    free(path_copy);
    return authored;
}
