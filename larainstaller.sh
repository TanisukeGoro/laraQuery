#!/usr/bin/env bash
scriptDir=`dirname $0`
server=""
database=""
function install_laradock() {
  git init
  print_msg_org "Install Laradock from Github....."
  git submodule add https://github.com/Laradock/laradock.git laradock || error_handling

  # Make src folder for Laravel source management
  mkdir src
  cd laradock
  cp env-example .env
  return 0
}

function print_msg_org(){
  printf "\e[33m$1\e[m\n"
}

function print_msg_ble(){
  printf "\e[36m$1\e[m\n"
}


function error_handling() {
  print_msg_org "Error....."
  exit
}

function replace_env() {
  sed -i _back "s@$1@$2@" .env
}

function select_server() {
  print_msg_org "What Web Servers do you use?"
  ans1="NGINX"
  ans2="Apache2"
  ans3="Caddy"
  select ANS in "$ans1" "$ans2" "$ans3"
  do

    if [ -z "$ANS" ]; then
      continue
     else
       break
    fi

  done
  print_msg_org "You selected"
  print_msg_ble "$REPLY ) $ANS"

  if [[ $REPLY -eq 1 ]]; then
    server='nginx'
  elif [[ $REPLY -eq 2 ]]; then
    server='apache2'
    replace_env "APACHE_DOCUMENT_ROOT=/var/www/" "APACHE_DOCUMENT_ROOT=/var/www/public"
  fi


}

function select_database() {
  print_msg_org "What Database Management Systems do you use?"

  ans1="MySQL"
  ans2="PostgreSQL"
  ans3="MariaDBf"
  ans4="Percona"
  ans5="MSSQL"
  ans6="MongoDB"
  ans7="Neo4j"
  ans8="RethinkDB"
  ans9="RethinkDB"

  select ANS in "$ans1" "$ans2" "$ans3" "$ans4" "$ans5" "$ans6" "$ans7" "$ans8" "$ans9"
  do

    if [ -z "$ANS" ]; then
      continue
     else
       break
    fi

  done
  print_msg_org "You selected"
  print_msg_ble "$REPLY ) $ANS"

  if [[ $REPLY -eq 1 ]]; then
    database=mysql
    replace_env "MYSQL_VERSION=latest" "MYSQL_VERSION=5.7"
    docker-compose up -d $server $database phpmyadmin
    composer_init $REPLY
  elif [[ $REPLY -eq 2 ]]; then
    database=postgres
    replace_env "WORKSPACE_INSTALL_PG_CLIENT=false" "WORKSPACE_INSTALL_PG_CLIENT=true"
    replace_env "PHP_FPM_INSTALL_MYSQLI=true" "PHP_FPM_INSTALL_MYSQLI=false"
    replace_env "PHP_FPM_INSTALL_PGSQL=false" "PHP_FPM_INSTALL_PGSQL=true"
    replace_env "PHP_FPM_INSTALL_PG_CLIENT=false" "PHP_FPM_INSTALL_PG_CLIENT=true"
    echo "Do you want to use PostGIS that is PostgreSQL extension module (y/n)? >"
    read answer
    if [ "$answer" != "${answer#[Yy]}" ] ;then
      replace_env "PHP_WORKER_INSTALL_PGSQL=false" "PHP_WORKER_INSTALL_PGSQL=true"
      replace_env "PHP_FPM_INSTALL_POSTGIS=false" "PHP_FPM_INSTALL_POSTGIS=true"
      sed -i '' -e 's/- postgres/- postgres-postgis/' docker-compose.yml
      database=postgres-postgis
    fi

    docker-compose up -d $server $database pgadmin
    composer_init $REPLY

  fi
}


function composer_init() {
  cp $scriptDir/init.sh ../src

  print_msg_org "Choice the Laravel versions"
  ans1="5.5(LTS)"
  ans2="5.6"
  ans3="5.7"
  ans4="5.8"
  ans5="6.0(LTS)"
  ans6="5.4 (not recommended)"

  select ANS in "$ans1" "$ans2" "$ans3" "$ans4" "$ans5" "$ans6"
  do

    if [ -z "$ANS" ]; then
      continue
     else
       break
    fi

  done
  print_msg_org "You selected"
  print_msg_ble "$REPLY ) $ANS"
  ANS=${ANS/" (not recommended)"/""}
  ANS=${ANS/"(LTS)"/""}
  sed -i _back "s@5.5.*@$ANS.*@" ../src/init.sh


  docker-compose exec workspace bash init.sh
  docker-compose stop

  print_msg_org "optimization..."
  cd ../src

  cp -pR ./src/. ./
  rm -rf src/


  if [[ $1 -eq 1 ]]; then
    replace_env "DB_HOST=127.0.0.1" "DB_HOST=mysql"
    replace_env "DB_DATABASE=homestead" "DB_DATABASE=default"
    replace_env "DB_USERNAME=homestead" "DB_USERNAME=default"

    cd ../laradock
    docker-compose up -d $server $database phpmyadmin
  elif [[ $1 -eq 2 ]]; then
    replace_env "DB_CONNECTION=mysql" "DB_CONNECTION=pgsql"
    replace_env "DB_HOST=127.0.0.1" "DB_HOST=$database"
    replace_env "DB_PORT=3306" "DB_PORT=5432"
    replace_env "DB_DATABASE=homestead" "DB_DATABASE=default"
    replace_env "DB_USERNAME=homestead" "DB_USERNAME=default"

    cd ../laradock
    docker-compose up -d $server $database pgadmin
  fi
  print_msg_ble "Succeed build up Laravel project !!"
  docker-compose exec workspace bash
}


function select_phpversions(){
  print_msg_org "Choice the PHP versions"
  7.3 - 7.2 - 7.1 - 7.0 - 5.6
  ans1="7.3"
  ans2="7.2"
  ans3="7.1"
  ans4="7.0"
  ans5="5.6 (not recommended)"
  select ANS in "$ans1" "$ans2" "$ans3" "$ans4" "$ans5"
  do

    if [ -z "$ANS" ]; then
      continue
     else
       break
    fi

  done
  ANS=${ANS/" (not recommended)"/""}
  replace_env "PHP_VERSION=7.2" "PHP_VERSION=$ANS"
}

function laradock_init() {
  replace_env "APP_CODE_PATH_HOST=../" "APP_CODE_PATH_HOST=../src"
  replace_env "DATA_PATH_HOST=~/.laradock/data" "DATA_PATH_HOST=../.laradock/data"

  print_msg_org "Input Project Name"
  dirName=`dirname $(pwd)`

  ans1=`basename ${dirName}`
  ans2="input my self"
  select ANS in "$ans1" "$ans2"
  do

    if [ -z "$ANS" ]; then
      continue
     else
       break
    fi

  done
  print_msg_ble "$REPLY ) $ANS"

  if [[  $REPLY -eq 2  ]]; then
    print_msg_org "Input Project Name"
    read ANS
  fi
  replace_env "COMPOSE_PROJECT_NAME=laradock" "COMPOSE_PROJECT_NAME=$ANS"
}

function main(){
  install_laradock
  laradock_init
  select_phpversions
  select_server
  select_database
}

main
