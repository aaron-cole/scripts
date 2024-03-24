#!/bin/bash

repos_to_sync="rhel-8-for-x86_64-baseos-rpms rhel-8-for-x86_64-supplementary-rpms rhel-8-for-x86_64-appstream-rpms"
download_dir="/reposync"


cd $download_dir
for repo_to_sync in $repos_to_sync; do
  reposync -p . --download-metadata -n --repoid=$repo_to_sync
done

for repo_to_sync in $repos_to_sync; do
  case $repo_to_sync in
    rhel-8-for-x86_64-baseos-rpms ) 
      for pkg in rhel-8-for-x86_64-baseos-rpms/Packages/*/*.rpm; do
        hammer repository --upload-content --id 1 --path $pkg
      done ;;
    rhel-8-for-x86_64-supplementary-rpms ) 
      for pkg in rhel-8-for-x86_64-supplementary-rpms/Packages/*/*.rpm; do
        hammer repository --upload-content --id 3 --path $pkg
      done ;;
    rhel-8-for-x86_64-appstream-rpms ) 
      for pkg in rhel-8-for-x86_64-appstream-rpms/Packages/*/*.rpm; do
        hammer repository --upload-content --id 4 --path $pkg
      done ;;
  esac
done