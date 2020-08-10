#!/bin/bash
ID=$(echo 'AUTO_promotions/a1/a11/a111/pre' | cut -d'/' -f2-)
DEPLOY_FOLDER=test

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
        rm -r $DEPLOY_FOLDER/$ENV_FOLDER -f
        mkdir $DEPLOY_FOLDER/$ENV_FOLDER
        mv ${directory::-1} $DEPLOY_FOLDER/$ENV_FOLDER/
      else
        for envfile in $(ls $1 | grep tfvars);
        do          	       
          echo "file $envfile"
          mv $1/$envfile $directory;      
        done;
        rec_function ${directory::-1};
      fi;
    done;    

}

rec_function a1