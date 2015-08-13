#!/bin/bash
set -e
[ -n "$ENV" -a "$ENV" != 'production' ] && set -x

if [ -z "$3" ]; then
  echo "$0 [--use-submodules] repo_root dest_dir treeish"
  echo
  echo "extracts specified mask in sparse-checkout to dest_dir from repo_root on treeish."
  exit 1
fi

if [ "$1" = "--use-submodules" ]; then
  use_submodules=1
  shift
fi

repo_root=$1
dest_dir=$2
treeish=$3


cd $repo_root

GIT_INDEX_FILE="$dest_dir/.index" git --work-tree="$dest_dir" read-tree -m -u $treeish

if [ "$use_submodules" ]; then
  cd $dest_dir
  GIT_INDEX_FILE=.index git --git-dir="$repo_root/.git" submodule update --init --recursive
  # TODO for sparse submodules see http://kshmakov.org/notes/th/2/ , e.g.:
  # git config core.sparsecheckout true
  # echo <this_submodule>/paths > $repo_root/.git/modules/<this_submodule>/info/sparse-checkout
fi

rm "$dest_dir/.index"
