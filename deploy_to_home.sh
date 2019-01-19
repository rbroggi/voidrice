#!/bin/bash

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
deploy_script_name=$(basename ${BASH_SOURCE[0]})
backup_dir=/tmp/home_deploy_backup

# links in home
only_on_home_links=$(diff \
	<(cd $script_dir && find ./ -type l | grep -v $(basename $script_dir) | sort) \
	<(cd $HOME && find ./ -type l | grep -v $(basename $script_dir) | sort) \
	| grep "^>" | sed 's/^> //g')

# retrieving links in home that are not links in repo
links_in_home_and_files_in_repo=""
for i in $only_on_home_links
do
	links_in_home_and_files_in_repo="$links_in_home_and_files_in_repo $(cd $script_dir && find $(dirname $i) -name "$(basename $i)")"
done

# removing links in home and creating backup link files in backup folder
for i in $links_in_home_and_files_in_repo
do
	echo "replacing $i symlink with file"
	echo "$(cd $HOME && ls -latr $i)"
	mkdir -p  ${backup_dir}
	echo "$(cd $HOME && ls -latr $i)" >> ${backup_dir}/backup_links.txt
	echo "rm $i"
	rm $i
done

# using rsync to override only changed files between repo and home (checksum) and back them up in the backup_dir with exclusions
echo "backup of changed files in ${backup_dir}"
echo "cd $script_dir && rsync --checksum -r --backup --backup-dir=${backup_dir} --exclude '.git' --exclude "${deploy_script_name}" $script_dir/ $HOME/"
cd $script_dir && rsync --checksum -r --backup --backup-dir=${backup_dir} --exclude '.git' --exclude "${deploy_script_name}" $script_dir/ $HOME/

