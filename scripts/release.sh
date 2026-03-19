#!/usr/bin/env bash

output_section "Building release version"

if ! execute_target "clean"; then
    output_error "Clean failed"
    return 1
fi

if ! execute_target "build"; then
    output_error "Build failed"
    return 1
fi

if ! execute_target "jar"; then
    output_error "JAR creation failed"
    return 1
fi

output_success "Release build completed: ${BUILD_DIR}/${JAR_OUTPUT}"
return 0
