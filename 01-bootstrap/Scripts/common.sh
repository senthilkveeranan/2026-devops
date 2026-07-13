#!/bin/bash

source logger.sh
source variables.sh
source functions.sh

info "Updating System"

dnf update -y

info "Installing Common Packages"

install_package git

install_package curl

install_package wget

install_package vim

install_package tree

install_package jq

install_package python3

success "Bootstrap Completed"
