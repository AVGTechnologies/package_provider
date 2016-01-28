#!/bin/bash

ONLY_FAILED=false
if [ "$1" = "--only-failed" ]; then
    ONLY_FAILED=true
    shift
fi

DAYS=$1
DIRECTORY=$2

show_help() {
    echo "Usage: [--only-failed] DAYS DIRECTORY"
    echo "DESCRIPTION"
    echo -e "\tDAYS"
    echo -e "\t\tnumber of days since modification (-1 to disable)"
    echo -e "\tDIRECTORY"
    echo -e "\t\tpath to the directory to be cleaned"
    echo -e "\t--only-failed"
    echo -e "\t\tspecifies that only <name>.error and corresponding <name>* files/directories will be deleted"
    echo "EXAMPLE:"
    echo -e "\tdelete_old_files.sh --only-failed -1 /path/to/directory/"
}

is_empty() {
    local var="$1"
    [ -z "$var" ]
}

is_number() {
    local var="$1"
    [[ $var =~ ^[0-9]+$ ]]
}

is_directory() {
    local path="$1"
    [ -d "$path" ]
}

main() {
    if ! is_directory "$DIRECTORY"; then
        echo "The given path is not a directory: ${DIRECTORY}"
        show_help
        exit 1
    fi

    local find_command="find $DIRECTORY -mindepth 1 -maxdepth 1"
    if ! [ "$DAYS" -eq -1 ]; then
        if ! is_number "$DAYS"; then
            echo "The DAYS argument must be greater or equal to -1."
            show_help
            exit 1
        fi
        find_command="$find_command -mtime +$DAYS"
    fi

    if [ "$ONLY_FAILED" = true ]; then
        echo 'only failed'
        readonly error_suffix=".error"
        data_to_delete=$($find_command -name *$error_suffix \
        | sed 's/\(.*\).error$/\1*/' | sort)
    else
      data_to_delete=$($find_command | sort)
    fi

    if ! is_empty data_to_delete; then
      for i in $(echo $data_to_delete ) ; do
          echo "deleting $i"
      done

      StartDate=$(date +%s)
      for i in $(echo $data_to_delete ) ; do
          mv $i $(echo $i | sed "s|$|.to_delete|")
      done
      FinalDate=$(date +%s)
      date -u -d "0 $FinalDate seconds - $StartDate seconds" +"moving took %H:%M:%S"

      du $DIRECTORY/*to_delete --max-depth=0 | awk -e 'BEGIN{a=0;}{a = a + $1}END{print a/1024/1024 " GB will be deleted in total"}'

      StartDate=$(date +%s)
      for i in $(echo $data_to_delete) ; do
          rm -rf "${i}.to_delete"
      done
      FinalDate=$(date +%s)
      date -u -d "0 $FinalDate seconds - $StartDate seconds" +"deleting took %H:%M:%S"
    fi
}

main

