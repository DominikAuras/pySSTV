#!/bin/bash

set -ex

if [[ x$(pip show virtualenv) == x ]] ; then
  sudo pip install virtualenv
fi

virtualenv --system-site-packages dbg
source dbg/bin/activate
pip install pillow cython pillowfight
pip install .
