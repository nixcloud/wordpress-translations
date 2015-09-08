#!/bin/sh
json=wp-languages.json

wget 'https://api.wordpress.org/translations/core/1.0/?version=4.3' -O $json

num=$(cat $json | jq '.translations | length ')
n=$(expr $num - 1)
echo "$n records found"

if [ ! -f .do_not_redownload_everything ]; then
  echo "running init on the GIT repository"
  rm -Rf db
  rm -Rf git
  
  mkdir db
  mkdir git
  
  pushd git
  git init
  echo "nixcloud polyglot git repo clone for reproducible packaging, contact js@lastlog.de for inquiries." > README.md
  git add README.md
  git commit -m 'first commit'
  git remote add origin git@github.com:nixcloud/wordpress-translations.git
  git push -u origin master
  popd
  touch .do_not_redownload_everything
fi

for i in `seq 0 $n`; do
  #if [ $i == 4 ]; then
  #exit
  #fi
  language=$(cat $json | jq ".translations[$i].language" | sed -e 's/\"//g')
  package=$(cat $json | jq ".translations[$i].package" | sed -e 's/\"//g')
  version=$(cat $json | jq ".translations[$i].version" | sed -e 's/\"//g')
  updated=$(cat $json | jq ".translations[$i].updated" | sed -e 's/\"//g')

  echo "------ $language ----------------------------------------------"
  echo $i $package $version $updated

  if [ "$version" != "4.3" ]; then
    echo "ignoring $language as $version too old"
    continue
  fi

  touch db/$language

  l=$(cat db/$language)
  if [ "$l" == "$updated" ]; then
    echo "no update for $language needed as "$l" equals "$updated""
  else
    echo "update for $language needed"
    mkdir tmp
    rm -Rf tmp/*
    wget "$package" -O tmp/${language}.zip
    ret=$?
    if [ $ret != 0 ]; then
      echo "download of ${language} failed, skipping this one..."
      continue
    fi
    pushd tmp
    unzip ${language}.zip
    rm ${language}.zip
    popd

    
    pushd git
    # check if branch exists already
    git checkout $language
    ret=$?
    if [ $ret != 0 ]; then
      # create a orphan branch with no prior history
      echo "git returned $ret, so creating orphan branch"
      git checkout --orphan $language
      git rm -rf .
    else
      rm -Rf *
    fi
    cp ../tmp/* .
    git add *
    git commit -m "$language: update $updated"
    popd

    rm -Rf tmp/*

    echo $updated > db/$language
  fi
done

pushd git
git checkout master
cp ../$0 .
git add $0
git commit -m "new version of $0"

git push --all origin
popd
