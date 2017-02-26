#!/bin/bash

source ./SECRET/config.sh

check_config () {
  if [ -z "$DOMAIN" ]; then
    echo '$DOMAIN is not set.'
    exit 1
  fi
  if [ -z "$PKI_PASSWORD" ]; then
    echo '$PKI_PASSWORD is not set.'
    exit 1
  fi
}

create_dirs () {
  mkdir -p ./SECRET/ca/
  mkdir -p ./SECRET/issued/
}

issue () {
if [ ! -f ./SECRET/ca/ca.key ]; then
  echo "The CA Root certificate needs to be generated first."

  echo "Creating CA file/directory structure..."
  mkdir -p ./SECRET/ca/archive
  cp /dev/null ./SECRET/ca/ca.db
  cp /dev/null ./SECRET/ca/ca.db.attr
  echo "01" > ./SECRET/ca/crt.srl
  echo "01" > ./SECRET/ca/crl.srl

  echo "Creating CA Root Certificate Request and key..."

  SAN="DNS:$DOMAIN" \
  openssl req -new \
    -config ./ca.conf \
    -out ./SECRET/ca/ca.csr \
    -keyout ./SECRET/ca/ca.key \
    -reqexts ca_reqext \
    -subj "/O=Internal Network/CN=Internal Network/DC=$DOMAIN/" \
    -passout pass:$PKI_PASSWORD \
    -batch

  echo "Creating CA Root Certificate..."

  SAN="DNS:$DOMAIN" \
  openssl ca -selfsign \
    -config ./ca.conf \
    -in ./SECRET/ca/ca.csr \
    -out ./SECRET/ca/ca.crt \
    -extensions ca_ext \
    -passin pass:$PKI_PASSWORD \
    -batch
else
  echo "The CA Root Certificate is already present, no need to re-create."
fi

if [ ! -f ./SECRET/issued/$1.crt ]; then
  CN="$1.$DOMAIN"
  SUBJECT="/O=Internal Network/CN=$CN/DC=$DOMAIN/"

  echo "Creating DEVICE \"$1\" Certificate Request and key..."

  SAN="DNS:$CN" \
  openssl req -new \
    -config ./ca.conf \
    -out ./SECRET/issued/$1.csr \
    -keyout ./SECRET/issued/$1.key \
    -reqexts device_reqext \
    -subj "$SUBJECT" \
    -nodes \
    -batch

  echo "Creating DEVICE \"$1\" Certificate..."

  SAN="DNS:$CN" \
  openssl ca \
    -config ./ca.conf \
    -in ./SECRET/issued/$1.csr \
    -out ./SECRET/issued/$1.crt \
    -extensions device_ext \
    -passin pass:$PKI_PASSWORD \
    -batch
else
  echo "SSL certificate for $1 already present."
fi
}

usage () {
  echo "Usage:"
  echo "./ssh.sh COMMAND"
  echo ""
  echo "COMMAND is one of the following:"
  echo "  help - Display this text."
  echo "  new [NAME] - Issue an SSL certificate for [NAME]."
  echo "  test - Test the config and system environment."
  echo "  purge - Delete EVERYTHING."
}

case $1 in
  test)
    check_config
    echo "All OK."
    ;;
  new)
    check_config
    create_dirs
    issue "$2"
    ;;
  purge)
    rm -rf ./SECRET/ca/
    rm -rf ./SECRET/issued/
    echo "Done."
    ;;
  *)
    usage
    ;;
esac
