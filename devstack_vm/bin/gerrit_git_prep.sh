#!/bin/bash -e
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DIR/config.sh

function usage() {
        echo "$0 --zuul-site ZUUL_SITE --gerrit-site GERRIT_SITE --zuul-ref ZUUL_REF --zuul-change ZUUL_CHANGE --zuul-project ZUUL_PROJECT [--git-origin GIT_ORIGIN] [--zuul-newrev ZUUL_NEWREV]"
}

while [ $# -gt 0 ];
do
    case $1 in
        --zuul-site)
            ZUUL_SITE=$2
            shift;;
        --gerrit-site)
            GERRIT_SITE=$2
            shift;;
        --git-origin)
            GIT_ORIGIN=$2
            shift;;
        --zuul-newrev)
            ZUUL_NEWREV=$2
            shift;;
        --zuul-ref)
            ZUUL_REF=$2
            shift;;
        --zuul-change)
            ZUUL_CHANGE=$2
            shift;;
        --zuul-project)
            ZUUL_PROJECT=$2
            shift;;
    esac
    shift
done

if [ -z "$ZUUL_REF" ] || [ -z "$ZUUL_CHANGE" ] || [ -z "$ZUUL_PROJECT" ]
then
        echo "ZUUL_REF ZUUL_CHANGE ZUUL_PROJECT are mandatory"
        exit 1
fi

PROJECT_DIR="$BUILDDIR/$(basename $ZUUL_PROJECT)"

function exit_error(){
        echo $1
        exit 1
}


if [ -z "$GERRIT_SITE" ]
then
  echo "The gerrit site name (eg 'https://review.openstack.org') must be the first argument."
  exit 1
fi

if [ -z "$ZUUL_SITE" ]
then
  echo "The zuul site name (eg 'http://zuul.openstack.org') must be the second argument."
  exit 1
fi

if [ -z "$GIT_ORIGIN" ] || [ -n "$ZUUL_NEWREV" ]
then
    GIT_ORIGIN="$GERRIT_SITE/p"
    # git://git.openstack.org/
    # https://review.openstack.org/p
fi

if [ -z "$ZUUL_REF" ]
then
    echo "This job may only be triggered by Zuul."
    exit 1
fi

if [ ! -z "$ZUUL_CHANGE" ]
then
    echo "Triggered by: $GERRIT_SITE/$ZUUL_CHANGE"
fi

if [ ! -d "$BUILDDIR" ]
then
        mkdir -p "$BUILDDIR" || exit_error "Failed to create build dir"
fi

if [ -d "$PROJECT_DIR" ]
then
	rm -rf "$PROJECT_DIR"
        mkdir -p  "$PROJECT_DIR" || exit_error "Failed to create project dir"
fi

cd "$PROJECT_DIR" || exit_error "Failed to enter project build dir"

set -x
if [[ ! -e .git ]]
then
    ls -a
    rm -fr .[^.]* *
    if [ -d /opt/git/$ZUUL_PROJECT/.git ]
    then
        git clone file:///opt/git/$ZUUL_PROJECT .
    else
        git clone $GIT_ORIGIN/$ZUUL_PROJECT .
    fi
fi
git remote set-url origin $GIT_ORIGIN/$ZUUL_PROJECT

# attempt to work around bugs 925790 and 1229352
if ! git remote update
then
    echo "The remote update failed, so garbage collecting before trying again."
    git gc
    git remote update
fi

git reset --hard
if ! git clean -x -f -d -q ; then
    sleep 1
    git clean -x -f -d -q
fi

echo "Before doing git checkout:"
echo "Git branch output:"
git branch
echo "Git log output:"
git log -10 --pretty=format:"%h - %an, %ae,  %ar : %s"

if echo "$ZUUL_REF" | grep -q ^refs/tags/
then
    git fetch --tags $ZUUL_URL/$ZUUL_PROJECT
    git checkout $ZUUL_REF
    git reset --hard $ZUUL_REF
elif [ -z "$ZUUL_NEWREV" ]
then
    git fetch $ZUUL_SITE/p/$ZUUL_PROJECT $ZUUL_REF
    git checkout FETCH_HEAD
    git reset --hard FETCH_HEAD
else
    git checkout $ZUUL_NEWREV
    git reset --hard $ZUUL_NEWREV
fi

if ! git clean -x -f -d -q ; then
    sleep 1
    git clean -x -f -d -q
fi

if [ -f .gitmodules ]
then
    git submodule init
    git submodule sync
    git submodule update --init
fi
echo "Final result:"
echo "Git branch output:"
git branch
echo "Git log output:"
git log -10 --pretty=format:"%h - %an, %ae,  %ar : %s"
