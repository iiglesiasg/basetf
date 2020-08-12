#!/bin/bash
DEPLOY_FOLDER=$1
echo "DF "$DEPLOY_FOLDER
## En caso de haber diferencias con la rama master, subimos la rama al repositorio.
## ARG:
#### $1: Directorio que contiene el repositorio destino.
#### $2: Nombre de la rama a subir.
push_branch(){
  cd $1
  git add .
  git commit -m "(BOT) commit"
  diff_number=$(git diff --name-only master | wc -l)
  if [ $diff_number -gt 0 ];
    then
      git push --set-upstream origin $2;
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
    echo "rec_function_tfvars arg1: $1 arg2: $2 arg3: $3 "
    for filename in $(ls $1 | grep tfvars);
      do 
        echo "move $filename to "$2/$3/$1/;
        mv $1/$filename $2/$3/$1/;
      done;   
      parent_folder=$(echo $1 | rev | cut -d '/' -f2- | rev );    
      if [ ${#1} -eq ${#parent_folder} ]; 
      then
        push_branch $2 $3;
      else
        rec_function_tfvars $parent_folder $2 $3;
      fi;
}

## En el repositorio destino, borramos la rama destino en caso de haberla y la recreamos en base a master
## ARG:
#### $1: Directorio que contiene el repositorio destino.
#### $2: Nombre de la rama y carpeta a crear
prepare_branch(){
  echo "prepare_branch arg1: "$1" arg2: "$2
  cd $1
  git checkout master
  # git push origin --delete $2
  git branch -a
  if [ $(git branch -a | grep "$(echo "$2")" | wc -l) -eq 0 ]; 
  then
    git branch $2
    git checkout $2;
  else 
    git checkout $2
    git pull;
  fi;
  # git branch $2
  # git checkout $2
  # rm -r $1/$2 -f
  last_dir=$(echo "$2" | tr '_' '/')
  mkdir -p $1/$2/$last_dir
}

## Aplanamos los TF en el repositorio destino, en la carpeta que le corresponde por ambiente. El nombre del
## TF en destino contiene el environment. Para los punteros, vamos a copiar el TF real y no el puntero (readlink). 
## ARG:
#### $1:Directorio de busqueda
flatten_tf(){
  echo "flatten_tf arg1: $1 pwd "$(pwd)
  str_to_replace=$(echo "$(pwd)" | tr '/' '_')
 # for link in $(ls -lrt $1/*.tf | grep ^l | awk '{print $9}');
 # do
 #   full_path=$(echo "$link" | tr '/' '_')
 #   tf_name=$(echo ${full_path//$str_to_replace'_'})  
 #   echo "fullpath: $full_path  tf_name: $tf_name"
 #   cp $link $DEPLOY_FOLDER/$ENV_FOLDER/$tf_name;
 # done;
 # find $1 -type l | xargs rm
  for file in $1/*.tf;
  do
    full_path_real_value=$(echo "$(readlink -f $file)" | tr '/' '_')
    tf_name=$(echo ${full_path_real_value//$str_to_replace'_'})
    cp $file $DEPLOY_FOLDER/$ENV_FOLDER/$tf_name;
  done;
}

## Subimos por los directorios mientras vamos propagando los TF con punteros. Cuando no se puede subir
## mas directorios se infiere el environment(el path relativo desde que comenzamos a
## iterar) que da nombre a una carpeta y a una rama en el repositorio destino. Aplanamos los TF y
## volcamos sobre la carpeta creada.
## ARG: 
#### $1: Directorio desde donde comenzar a iterar. Debe ser 'environments' para la estructura actual
## CALL:
#### prepare_branch: Comandos git
#### rec_function_tfvars: Para mover los tfvars pero manteniendo la estructura de carpetas 
#### rec_function: Llamada recursiva
rec_function() 
{
    echo "rec_function ARG1: $1"
    X=$1/*/  
    for directory in $X;
    do     
      if [ $(echo "$directory" | tr '/' '_') = $(echo "$X" | tr '/' '_') ];
      then 
        ENV_FOLDER=$(echo "$1" | cut -d '/' -f2- | tr '/' '_');
        WORKING_DIR=$(pwd)
        prepare_branch $DEPLOY_FOLDER $ENV_FOLDER
        cd $WORKING_DIR
        flatten_tf $1
        rec_function_tfvars $1 $DEPLOY_FOLDER $ENV_FOLDER
        cd $WORKING_DIR
      else
        for envfile in $(ls $1/*.tf);
        do          	       
          ln -s $(readlink -f $envfile) $directory;      
        done;
        rec_function ${directory::-1};
      fi;
    done;    

}

cd iac
rec_function environments