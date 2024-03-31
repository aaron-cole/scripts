#!/bin/bash

repos_to_sync="rhel-8-for-x86_64-baseos-rpms rhel-8-for-x86_64-supplementary-rpms rhel-8-for-x86_64-appstream-rpms"
download_dir="/reposync"

function get_list {
  cd $download_dir
  if [ -f $repo_to_sync-package_list.csv ]; then
    rm -rf $repo_to_sync-package_list.csv
  fi
  hammer --csv --output-file $repo_to_sync-package_list.csv package list --repository-id $my_id
}

function repo_sync {
  cd $download_dir
  reposync -p . --download-metadata -n --repoid=$repo_to_sync
}

function clean_up {
  cd $download_dir/$repo_to_sync/Packages
  for package in */*.rpm; do
    my_package=$(echo $package | cut -f2 -d"/")
    if grep $my_package $download_dir/$repo_to_sync-package_list.csv >> /dev/null; then
      rm -rf $package
    fi
  done
}

function hammer_upload {
  cd $download_dir
  if [ $(ls $download_dir/$repo_to_sync/Packages/*/*.rpm | wc -l) -gt 0 ]; then
    for my_rpm in $download_dir/$repo_to_sync/Packages/*/*.rpm; do
      hammer repository upload-content --id $my_id --path $my_rpm && rm -rf $my_rpm
    done
  fi
}


############################

cd $download_dir

for repo_to_sync in $repos_to_sync; do
  case $repo_to_sync in
    rhel-8-for-x86_64-baseos-rpms ) 
      my_id='1'
      get_list && repo_sync
      clean_up && hammer_upload
      ;;
    rhel-8-for-x86_64-supplementary-rpms ) 
      my_id='3'
      get_list && repo_sync
      clean_up && hammer_upload
      ;;
    rhel-8-for-x86_64-appstream-rpms ) 
      my_id='4'
      get_list && repo_sync
      clean_up && hammer_upload
      ;;
  esac
done
#######################################
