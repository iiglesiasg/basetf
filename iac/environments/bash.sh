#!/bin/bash
ID=$(echo 'AUTO_promotions/a1/a11/a111/pre' | cut -d'/' -f2-)
DEPLOY_FOLDER=test

rec_function() 
{ 
    for directory in $1/*/;
    do 
      if [ $directory = $1'/*/' ]; 
      then 
        ENV_FOLDER=echo $1 | tr '/' '_';
        rm -r $DEPLOY_FOLDER/ENV_FOLDER -f
        mkdir $DEPLOY_FOLDER/ENV_FOLDER
        mv $directory/* $DEPLOY_FOLDER/ENV_FOLDER
      else
        for file in *.{tf,tfvars};
        do
          mv file $directory;          
        done;
        rec_function $directory;
      fi
    done;    

}

rec_function .


