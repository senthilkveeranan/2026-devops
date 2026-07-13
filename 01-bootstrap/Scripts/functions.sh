#!/bin/bash

install_package(){

PACKAGE=$1

dnf install -y "$PACKAGE"

}

enable_service(){

SERVICE=$1

systemctl enable --now "$SERVICE"

}

check_service(){

SERVICE=$1

systemctl is-active "$SERVICE"

}
