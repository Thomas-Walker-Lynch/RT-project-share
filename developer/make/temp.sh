sed -E '
s/\bC_SOURCE_DIR_OK\b/c_source_dir_ok/g;
s/\bC_SOURCE_LIB\b/c_source_lib/g;
s/\bC_SOURCE_EXEC\b/c_source_exec/g;
s/\bC_BASE_LIB\b/c_base_lib/g;
s/\bC_BASE_EXEC\b/c_base_exec/g;
s/\bOBJECT_LIB\b/object_lib/g;
s/\bOBJECT_EXEC\b/object_exec/g;
s/\bEXEC\b/exec_/g
' target_library_CLI.mk > target_library_CLI.new.mk
