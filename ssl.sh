#!/bin/bash

mkdir -p ./SECRET/ca/
mkdir -p ./SECRET/devices/

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
    -config ./SECRET/ca.conf \
    -out ./SECRET/ca/ca.csr \
    -keyout ./SECRET/ca/ca.key \
    -reqexts ca_reqext \
    -subj "/O=Internal Network/CN=Internal Network/DC=$DOMAIN/" \
    -passout pass:$PKI_PASSWORD \
    -batch

  echo "Creating CA Root Certificate..."

  SAN="DNS:$DOMAIN" \
  openssl ca -selfsign \
    -config ./SECRET/ca.conf \
    -in ./SECRET/ca/ca.csr \
    -out ./SECRET/ca/ca.crt \
    -extensions ca_ext \
    -passin pass:$PKI_PASSWORD \
    -batch
else
  echo "The CA Root Certificate is already present, no need to re-create."
fi

if [ ! -f ./SECRET/issued/$2.crt ]; then
  CN="$2.$DOMAIN"
  SUBJECT="/O=Internal Network/CN=$CN/DC=$DOMAIN/"

  echo "Creating DEVICE \"$2\" Certificate Request and key..."

  SAN="DNS:$CN" \
  openssl req -new \
    -config ./SECRET/ca.conf \
    -out ./SECRET/issued/$2.csr \
    -keyout ./SECRET/issued/$2.key \
    -reqexts device_reqext \
    -subj "$SUBJECT" \
    -nodes \
    -batch

  echo "Creating DEVICE \"$2\" Certificate..."

  SAN="DNS:$CN" \
  openssl ca \
    -config ./SECRET/ca.conf \
    -in ./SECRET/issued/$2.csr \
    -out ./SECRET/issued/$2.crt \
    -extensions device_ext \
    -passin pass:$PKI_PASSWORD \
    -batch
else
  echo "SSL certificate for $2 already present."
fi
