#!/bin/bash
set -e

array_to_regex()
{
    local ar=(${@})
    local regex=""

    for s in "${ar[@]}"
    do
        if [ "$regex" ]; then
            regex+="\\|"
        fi
        regex+="^"$(echo $s | sed -e 's/[]\/$*.^|[]/\\&/g')
    done
    echo $regex
}

tests_dir=$1
tests_type=${2:-default}

exclude_tests_file="/home/ubuntu/bin/excluded-tests.txt"
isolated_tests_file="/home/ubuntu/bin/isolated-tests.txt"
include_tests_file="/home/ubuntu/bin/include-tests.txt"

if [ -f "$include_tests_file" ]; then
    include_tests=(`awk 'NF && $1!~/^#/' $include_tests_file`)
    include_regex=$(array_to_regex ${include_tests[@]})
else
    echo "Could not find tests file: $include_tests_file"
    exit 1
fi

if [ -f "$exclude_tests_file" ]; then
    exclude_tests=(`awk 'NF && $1!~/^#/' $exclude_tests_file`)
    exclude_regex=$(array_to_regex ${exclude_tests[@]})
else
    exclude_regex='^$'
fi

if [ -f "$isolated_tests_file" ]; then
    isolated_tests=(`awk 'NF && $1!~/^#/' $isolated_tests_file`)
    isolated_regex=$(array_to_regex ${isolated_tests[@]})
else
    isolated_regex='^$'
fi

cd $tests_dir
case "$tests_type" in
    default)
    	testr list-tests | grep $include_regex | grep -v $exclude_regex | grep -v $isolated_regex
        ;;

    isolated)
	if [ -f "$isolated_tests_file" ]; then
            testr list-tests | grep $isolated_regex
	fi
        ;;

    *)
        echo "Invalid tests_type: $tests_type"
        exit 1
esac
