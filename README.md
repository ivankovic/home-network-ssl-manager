# Home network SSL management.

## Clone the repository.

```
git clone git@github.com:ivankovic/home-network-ssl-manager.git
```

## Create a secure SECRET directory.

```
cd clone
ln -s <INSERT ENCRYPTED FOLDER NAME HERE> SECRET
```

## Create a config file

```
echo "#!/bin/bash" > ./SECRET/config.sh
echo "DOMAIN=<INSERT INTERNAL DOMAIN HERE>" >> ./SECRET/config.sh
echo "PKI_PASSWORD=<SOME REALLY LONG RANDOM STRING HERE>" >> ./SECRET/config.sh
```

## Issue certificates

```
./ssl.sh new <NAME>
```

# Licence

AGPL-3.0
