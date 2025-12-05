#!/bin/bash

print_info() {
    echo -e "${BLUE}ℹ${NC} $@"
}

print_success() {
    echo -e "${GREEN}✓${NC} $@"
}

print_error() {
    echo -e "${RED}✗${NC} $@"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $@"
}
