#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

source $DIR/config.sh

while [ $# -gt 0 ];
do
    case $1 in
        --branch)
            ZUUL_BRANCH=$2
            shift;;
        --build-for)
            ZUUL_PROJECT=$2
            shift;;
    esac
    shift
done

PROJECT_NAME=$(basename $ZUUL_PROJECT)
echo "Branch: $ZUUL_BRANCH"
echo "Project: $ZUUL_PROJECT"
echo "Project Name: $PROJECT_NAME"

pushd "$DEVSTACK_DIR"
find . -name *pyc -print0 | xargs -0 rm -f
git reset --hard
git clean -f -d
git fetch
git checkout "$ZUUL_BRANCH" || echo "Failed to switch branch $ZUUL_BRANCH"
git pull
echo "Devstack final branch:"
git branch
echo "Devstack git log:"
git log -10 --pretty=format:"%h - %an, %ae,  %ar : %s"
popd

if [ ! -d "$BUILDDIR" ]
then
    echo "This node has not been stacked"
    exit 1
fi

pushd "$BUILDDIR"
#clean any .pyc files
find . -name *pyc -print0 | xargs -0 rm -f
# Update all repositories except the one testing the patch.
for i in `ls -A`
do
	if [[ "$i" != "$PROJECT_NAME" ]] && [[ -d $i ]]
	then
		if pushd "$i"
		then
	        	if [ -d ".git" ]
        		then
        			git reset --hard
        			git clean -f -d
        			git fetch
        			git checkout "$ZUUL_BRANCH" || echo "Failed to switch branch $ZUUL_BRANCH"
				git pull
        		fi
			echo "Folder: $BUILDDIR/$i"
			echo "Git branch output:"
			git branch
			echo "Git Log output:"
			if ! [[ $i =~ .*noVNC.* ]]
			then
				git status
				git log -10 --pretty=format:"%h - %an, %ae,  %ar : %s"
			fi
			popd
		else
			echo "Error trying to update $i"
		fi
	fi
done

popd
