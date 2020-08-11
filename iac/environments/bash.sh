#!/bin/bash
DEPLOY_FOLDER=test

## En caso de haber diferencias con la rama master, subimos la rama al repositorio.
## ARG:
#### $1: Directorio que contiene el repositorio destino.
#### $2: Nombre de la rama a subir.
push_branch(){
  cd $1
  git add .
  git commit -m "(BOT) commit"
  diff_number=$(git diff --name-only master | wc -l)
  if $diff_number -gt 0;
    then
      git push -u origin $2;
    fi;
}

## Bajamos por los directorios moviendo los TFVARS al repositorio destino, conservando la estructura del 
## repositorio origen.
## ARG:
#### $1: Directorio donde comenzar a iterar. 
#### $2: Directorio que contiene el repositorio destino.
#### $3: Nombre de la carpeta/rama/entorno destino.
## CALL: 
#### push_branch: Comandos git.
#### rec_function_tfvars: Llamada recursiva.
rec_function_tfvars(){
  
    for filename in $(ls $1 | grep tfvars);
      do 
        mv $1/$filename $2/$3/$1/;
      done;   
      parent_folder=$(echo $1 | rev | cut -d '/' -f2- | rev );    
      if [ ${#1} -eq ${#parent_folder} ]; 
      then
        push_branch $2 $3;
      else
        rec_function_tfvars $parent_folder $2;
      fi;
}

## En el repositorio destino, borramos la rama destino en caso de haberla y la recreamos en base a master
## ARG:
#### $1: Directorio que contiene el repositorio destino.
#### $2: Nombre de la rama y carpeta a crear
prepare_branch(){
  cd $1
  git checkout master
  git push --delete $2
  git branch $2
  git checkout $2
  rm -r $1/$2 -f
  mkdir $1/$2
}

## Subimos por los directorios mientras vamos propagando los tf. Cuando no se puede subir
## mas directorios podemos inferir el environment(el path relativo desde que comenzamos a
## iterar) que dara nombre a una carpeta y a una rama en el repositorio destino. En este
## punto ya tenemos aplanados los archivos TF que volcamos sobre la carpeta creada.
## ARG: 
#### $1: Directorio desde donde comenzar a iterar. Debe ser 'environments' para la estructura actual
## CALL:
#### prepare_branch: Comandos git
#### rec_function_tfvars: Para mover los tfvars pero manteniendo la estructura de carpetas 
#### rec_function: Llamada recursiva
rec_function() 
{
    X=$1/*/
   # echo "X $X"    
    for directory in $X;
    do 
    #  echo "directory $directory"
      if [ $(echo "$directory" | tr '/' '_') = $(echo "$X" | tr '/' '_') ];
      then 
        echo "fin root $directory"
        ENV_FOLDER=$(echo "$1" | tr '/' '_');
        WORKING_DIR=$(pwd)
        prepare_branch $DEPLOY_FOLDER $ENV_FOLDER
        # rm -r $DEPLOY_FOLDER/$ENV_FOLDER -f
        # mkdir $DEPLOY_FOLDER/$ENV_FOLDER
        echo "wd: "$WORKING_DIR" pwd "$(pwd) 
        cd WORKING_DIR
        mv ${directory::-1} $DEPLOY_FOLDER/$ENV_FOLDER/
        rec_function_tfvars $1 $DEPLOY_FOLDER $ENV_FOLDER
      else
        for envfile in $(ls $1/*.tf);
        do          	       
          echo "file $envfile"
          mv $1/$envfile $directory;      
        done;
        rec_function ${directory::-1};
      fi;
    done;    

}

cd iac
rec_function environments