#!/bin/bash

mkdir -p ./SECRET/pki/$1/ca/
mkdir -p ./SECRET/pki/$1/issued/

if [ ! -f ./SECRET/pki/$1/ca/ca.key ]; then
  echo "Creating a new Certificate Authority for $1 devices..."

  echo "Creating $1 CA file/directory structure..."
  mkdir -p ./SECRET/pki/$1/ca/archive
  cp /dev/null ./SECRET/pki/$1/ca/ca.db
  cp /dev/null ./SECRET/pki/$1/ca/ca.db.attr
  echo "01" > ./SECRET/pki/$1/ca/crt.srl
  echo "01" > ./SECRET/pki/$1/ca/crl.srl

  echo "Creating $1 CA Root Certificate Request and key..."

  SAN="DNS:$DOMAIN" \
  openssl req -new \
    -config ./SECRET/pki/$1/ca.conf \
    -out ./SECRET/pki/$1/ca/ca.csr \
    -keyout ./SECRET/pki/$1/ca/ca.key \
    -reqexts ca_reqext \
    -subj "/O=Internal Network/CN=Internal Network/DC=$DOMAIN/" \
    -passout pass:$PKI_PASSWORD \
    -batch

  echo "Creating $1 CA Root Certificate..."

  SAN="DNS:$DOMAIN" \
  openssl ca -selfsign \
    -config ./SECRET/pki/$1/ca.conf \
    -in ./SECRET/pki/$1/ca/ca.csr \
    -out ./SECRET/pki/$1/ca/ca.crt \
    -extensions ca_ext \
    -passin pass:$PKI_PASSWORD \
    -batch
else
  echo "Found $1 CA!"
fi

if [ ! -f ./SECRET/pki/$1/issued/$2.crt ]; then
  CN="$2.$DOMAIN"
  SUBJECT="/O=Internal Network/CN=$CN/DC=$DOMAIN/"

  echo "Creating $1 DEVICE \"$2\" Certificate Request and key..."

  SAN="DNS:$CN" \
  openssl req -new \
    -config ./SECRET/pki/$1/ca.conf \
    -out ./SECRET/pki/$1/issued/$2.csr \
    -keyout ./SECRET/pki/$1/issued/$2.key \
    -reqexts device_reqext \
    -subj "$SUBJECT" \
    -nodes \
    -batch

  echo "Creating $1 DEVICE \"$2\" Certificate..."

  SAN="DNS:$CN" \
  openssl ca \
    -config ./SECRET/pki/$1/ca.conf \
    -in ./SECRET/pki/$1/issued/$2.csr \
    -out ./SECRET/pki/$1/issued/$2.crt \
    -extensions device_ext \
    -passin pass:$PKI_PASSWORD \
    -batch
else
  echo "SSL certificate for $2 already present."
fi
