#!/usr/bin/env bash

output_section "Development build"

BUILD_DIR="output/dev"

if ! execute_target "build"; then
    output_error "Build failed"
    return 1
fi

output_success "Development build completed"
return 0
