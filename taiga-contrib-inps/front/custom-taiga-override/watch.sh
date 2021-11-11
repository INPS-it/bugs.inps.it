#!/bin/bash
# $1: directory dove controllare i file
# $2: directory di destinazione per la copia dei files
while true; do
  for f in "$1"; do
    date
    echo "Checking $f and subfolders"
    find=$(find "$f" -type f)
    while read -r f2; do
      # strip non-alphanumeric from filename for a variable var name
      v=${f2//[^[:alnum:]]/}
      r=$(md5sum "$f2")
      if [ "$r" = "${!v}" ]; then
        : #echo "Identical $f2"
      else
        echo "$f2 has been changed"

        if test -f "$2/$f2"; then
          # $f2 esiste, dobbiamo verificare se è diverso
          checksumf2=$(md5sum "$2/$f2")

          if [ "$r" != "$checksumf2" ]; then
              # I file differiscono, vanno copiati
              cp $f2 $2/$f2
          fi

        else
          # $f2 non esiste, lo copiamo direttamente
          cp $f2 $2/$f2
        fi


      fi
      eval "${v}=\$r"
    done <<<"$find"
  done
  sleep 2
done
