#!/bin/sh

timestamp=$(date +%Y-%m-%d--%H:%M:%S)

if [[ $# -eq 0 ]]; then
  v=`$0 bar 2>&1`
  echo "$v" > $timestamp.log
  exit
fi

# remove json documents older than 50 days
find json/* -mtime +50 -exec rm {} \;

#############  create empty git repo ###########################################
if [ ! -f .do_not_redownload_everything ]; then
  echo "running init on the GIT repository"
  rm -Rf db
  rm -Rf git
  rm -Rf json
  
  mkdir db
  mkdir git
  mkdir json
  
  pushd git
  git init
  cp ../README.raw > README.md
  git add README.md
  git commit -m 'first commit'
  git remote add origin git@github.com:nixcloud/wordpress-translations.git
  git push -u origin master
  popd
  touch .do_not_redownload_everything
fi
#############  /create empty git repo ###########################################




#############  get a list of current versiosn ###########################################
versionFile="json/versions-$timestamp.json"
curl https://api.wordpress.org/core/version-check/1.7/ | jq '.' > $versionFile

num=$(cat $versionFile | jq '.offers | length ')
n=$(expr $num - 1)

foundVersions=""

for i in `seq 0 $n`; do
  version=$(cat $versionFile| jq ".offers[$i].version" | egrep -o '[0-9]+.[0-9]+')
#   echo $version
  majorVersion=$(expr substr $version 1 1)
  if [ $majorVersion -lt 4 ]; then
    continue
  fi
  foundVersions+=$version
  foundVersions+=" "
done

echo "this are the versions >= 4.x series"
echo "   " $foundVersions
#############  /get a list of current versiosn ###########################################













#############  download all found languages ###########################################

for versionIterator in $foundVersions; do

  languageJson=json/wp-languages-$timestamp-$versionIterator.json

  curl "https://api.wordpress.org/translations/core/1.0/?version=$versionIterator" | jq '.' >  $languageJson

  num=$(cat $languageJson | jq '.translations | length ')
  n=$(expr $num - 1)
  echo "$n records found"

  for i in `seq 0 $n`; do
    language=$(cat $languageJson | jq ".translations[$i].language" | sed -e 's/\"//g')
     package=$(cat $languageJson | jq ".translations[$i].package" | sed -e 's/\"//g')
     version=$(cat $languageJson | jq ".translations[$i].version" | sed -e 's/\"//g')
     updated=$(cat $languageJson | jq ".translations[$i].updated" | sed -e 's/\"//g')

    echo "------ ${language}-${versionIterator} ----------------------------------------------"
    echo $i $package $version $updated

    touch db/${language}-${versionIterator}

    l=$(cat db/${language}-${versionIterator})
    if [ "$l" == "$updated" ]; then
      echo "no update for ${language}-${versionIterator} needed as "$l" equals "$updated""
    else
      echo "update for ${language}-${versionIterator} needed"
      mkdir tmp
      rm -Rf tmp/*
      wget "$package" -O tmp/${language}.zip
      ret=$?
      if [ $ret != 0 ]; then
        echo "download of ${language}-${versionIterator} failed, skipping this one..."
        continue
      fi
      pushd tmp
      unzip ${language}.zip
      rm ${language}.zip
      popd
      
      pushd git
      # check if branch exists already
      git checkout ${language}-${versionIterator}
      ret=$?
      if [ $ret != 0 ]; then
        # create a orphan branch with no prior history
        echo "git returned $ret, so creating orphan branch"
        git checkout --orphan ${language}-${versionIterator}
        git rm -rf .
      else
        rm -Rf *
      fi
      cp ../tmp/* .
      git add *
      git commit -m "${language}-${versionIterator}: update $updated"
      popd

      rm -Rf tmp/*

      echo $updated > db/${language}-${versionIterator}
    fi
  done
done
#############  /download all found languages ###########################################



exit

pushd git
git checkout master
cp ../$0 .
git add $0
git commit -m "new version of $0"

git push --all origin
popd
