#!/bin/bash

# Variables del archivo de texto a cifrar
file="$1"
content=$(<"$file")
filename=$(basename "$file" .txt)
directory=$(dirname "$file")

# Cifrar archivo por sustitución
encrypted_content=$(echo $content | tr 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ' 'nopqrstuvwxyzabcdefghijklmNOPQRSTUVWXYZABCDEFGHIJKLM')

# Cifrar archivo por transposición
encrypted_content=$(echo $encrypted_content | rev)

# Guardar archivo cifrado
encrypted_file="$directory/encrypted_${filename}.txt"

echo "$encrypted_content" > "$encrypted_file"
echo 'Archivo cifrado correctamente.'