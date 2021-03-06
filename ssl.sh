#!/bin/bash

source ./SECRET/config.sh

check_config () {
  FAIL=false
  if [ -z "$DOMAIN" ]; then
    echo '$DOMAIN is not set.'
    FAIL=true
  fi
  if [ -z "$PKI_PASSWORD" ]; then
    echo '$PKI_PASSWORD is not set.'
    FAIL=true
  fi
  if [ -z "$ORGANIZATION" ]; then
    echo '$ORGANIZATION is not set.'
    FAIL=true
  fi
  if [ "$FAIL" = true ]; then
    exit 1
  fi
}

create_dirs () {
  mkdir -p ./SECRET/ca/
  mkdir -p ./SECRET/issued/
  mkdir -p ./SECRET/ca/archive
}

ensure_clr_exists () {
  if [ ! -f ./SECRET/ca/ca.crl ]; then
    echo "CRL does not exist yet. Creating a new CRL."

    SAN="DNS:$DOMAIN" \
    ON="$ORGANIZATION" \
    openssl ca \
      -config ./ca.conf \
      -passin pass:$PKI_PASSWORD \
      -gencrl \
      -out ./SECRET/ca/ca.crl
  else
    echo "CRL exists."
  fi
}

issue () {
  if [ ! -f ./SECRET/ca/ca.key ]; then
    echo "The CA Root certificate needs to be generated first."

    echo "Creating CA file/directory structure..."
    cp /dev/null ./SECRET/ca/ca.db
    cp /dev/null ./SECRET/ca/ca.db.attr
    echo "01" > ./SECRET/ca/crt.srl
    echo "01" > ./SECRET/ca/crl.srl

    echo "Creating CA Root Certificate Request and key..."

    SAN="DNS:$DOMAIN" \
      ON="$ORGANIZATION" \
      openssl req -new \
      -config ./ca.conf \
      -out ./SECRET/ca/ca.csr \
      -keyout ./SECRET/ca/ca.key \
      -reqexts ca_reqext \
      -subj "/O=$ORGANIZATION/CN=$ORGANIZATION/DC=$DOMAIN/" \
      -passout pass:$PKI_PASSWORD \
      -batch

    echo "Creating CA Root Certificate..."

    SAN="DNS:$DOMAIN" \
      ON="$ORGANIZATION" \
      openssl ca -selfsign \
      -config ./ca.conf \
      -in ./SECRET/ca/ca.csr \
      -out ./SECRET/ca/ca.crt \
      -extensions ca_ext \
      -passin pass:$PKI_PASSWORD \
      -batch

    ensure_clr_exists
  else
    echo "The CA Root Certificate is already present, no need to re-create."
  fi

  if [ ! -f ./SECRET/issued/$1.crt ]; then
    CN="$1.$DOMAIN"
    SUBJECT="/O=$ORGANIZATION/CN=$CN/DC=$DOMAIN/"

    echo "Creating DEVICE \"$1\" Certificate Request and key..."

    SAN="DNS:$CN" \
      ON="$ORGANIZATION" \
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
      ON="$ORGANIZATION" \
      openssl ca \
      -config ./ca.conf \
      -in ./SECRET/issued/$1.csr \
      -out ./SECRET/issued/$1.crt \
      -extensions device_ext \
      -passin pass:$PKI_PASSWORD \
      -batch

    echo "Packaging the certificate. You will need to choose a password here."

    openssl pkcs12 -export -clcerts \
      -in ./SECRET/issued/$1.crt \
      -inkey ./SECRET/issued/$1.key \
      -out ./SECRET/issued/$1.p12
  else
    echo "SSL certificate for $1 already present."
  fi
}

revoke () {
  if [ ! -f ./SECRET/ca/ca.key ]; then
    echo "The CA Root certificate needs to be generated first."
  else
    ensure_clr_exists

    echo "Revoking DEVICE \"$1\" Certificate..."

    SAN="DNS:$CN" \
      ON="$ORGANIZATION" \
      openssl ca \
      -config ./ca.conf \
      -passin pass:$PKI_PASSWORD \
      -revoke ./SECRET/issued/$1.crt \
      -batch
  fi
}

usage () {
  echo "Usage:"
  echo "./ssh.sh COMMAND"
  echo ""
  echo "COMMAND is one of the following:"
  echo "  new [NAME] - Issue an SSL certificate for [NAME]."
  echo "  remove [NAME] - Revoke the SSL certificate for [NAME]."
  echo "  revoke [NAME] - Revoke the SSL certificate for [NAME]."
  echo "  purge - Delete EVERYTHING."
  echo "  list - List issued certificates."
  echo "  test - Test the config and system environment."
  echo "  help - Display this text."
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
    echo "Done."
    ;;
  remove)
    revoke "$2"
    echo "Done."
    ;;
  revoke)
    revoke "$2"
    echo "Done."
    ;;
  purge)
    rm -rf ./SECRET/ca/
    rm -rf ./SECRET/issued/
    echo "Done."
    ;;
  list)
    for i in ./SECRET/issued/*.p12; do
      echo ${i#./SECRET/issued/};
    done
    ;;
  *)
    usage
    ;;
esac
