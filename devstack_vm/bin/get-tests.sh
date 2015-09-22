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

project=$1
tests_dir=$2
test_suite=${3:-"default"}

exclude_tests_file="/home/ubuntu/bin/excluded-tests.txt"
isolated_tests_file="/home/ubuntu/bin/isolated-tests.txt"

if [ -f "$exclude_tests_file" ]; then
    exclude_tests=(`awk 'NF && $1!~/^#/' $exclude_tests_file`)
fi

if [ -f "$isolated_tests_file" ]; then
    isolated_tests=(`awk 'NF && $1!~/^#/' $isolated_tests_file`)
fi

exclude_tests=( ${exclude_tests[@]} ${isolated_tests[@]} )
exclude_regex=$(array_to_regex ${exclude_tests[@]})

cd $tests_dir

if [ ! "$exclude_regex" ]; then
    exclude_regex='^$'
fi


if [[ $project == "nova" ]]; then
    testr list-tests | grep -v $exclude_regex
elif [[ $project == "neutron" ]]; then

    testr list-tests | grep "tempest.api.network" | grep -v $exclude_regex
else
    echo "ERROR: Cannot test for project $project"
    exit 1
fi
