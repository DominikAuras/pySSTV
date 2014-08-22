#!/bin/bash

set -ex

if [[ x$(pip show virtualenv) == x ]] ; then
  sudo pip install virtualenv
fi

virtualenv --system-site-packages dbg
source dbg/bin/activate
pip install pillow cython pillowfight

cython pysstv/*.pyx
python setup.py build_ext --inplace
nosetests pysstv/tests

pip install .
