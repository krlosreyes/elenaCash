#!/bin/bash
# Ejecutar desde la carpeta raíz del proyecto (elenacash_app/)
# Genera el keystore de release para Android

KEYSTORE_PATH="android/elenacash-release.keystore"
KEY_ALIAS="elenacash"

echo "=== Generando keystore de release para ElenaCash ==="
echo "Se pedirá una contraseña para el keystore y para la clave."
echo "GUARDA ESTAS CONTRASEÑAS — sin ellas no podrás actualizar la app en Google Play."
echo ""

keytool -genkey -v \
  -keystore $KEYSTORE_PATH \
  -alias $KEY_ALIAS \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -dname "CN=ElenaCash, OU=Mobile, O=ElenaCash, L=Bogota, S=Cundinamarca, C=CO"

echo ""
echo "=== Keystore generado en: $KEYSTORE_PATH ==="
echo ""
echo "Ahora crea el archivo android/key.properties con:"
echo "  storePassword=<la contraseña que pusiste>"
echo "  keyPassword=<la contraseña de la clave>"
echo "  keyAlias=elenacash"
echo "  storeFile=../elenacash-release.keystore"
