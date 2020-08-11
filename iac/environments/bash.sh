#!/bin/bash
DEPLOY_FOLDER=test

push_branch(){
  cd $1
  git add .
  git commit -m "(BOT) commit"
  diff_number=$(git diff --name-only master | wc -l)
  if $diff_number -gt 0;
    then
      git push -u origin $3;
    fi;
}

rec_functin_tfvars(){
  
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

prepare_branch(){
  cd $1
  git checkout master
  git push --delete $2
  git branch $2
  git checkout $2
  rm -r $1/$2 -f
  mkdir $1/$2
}

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

rec_function a1