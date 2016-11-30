#!/bin/bash

set -e

# commit message of current head of RMG-tests = SHA1-ID of RMG-Py/database commit to be tested.
MESSAGE=$(git log --format=%B -n 1 HEAD)
echo "Message: "$MESSAGE

export BRANCH=$TRAVIS_BRANCH
echo "Branch: "$BRANCH

# create a folder with benchmark version of RMG-Py and RMG-database:
# go to parent-folder of the RMG-tests repo:
cd ..
# prepare benchmark RMG-Py and RMG-db
export benchmark=$PWD/code/benchmark2
rm -rf $benchmark
mkdir -p $benchmark
cd $benchmark

# clone benchmark RMG-Py
git clone https://github.com/ReactionMechanismGenerator/RMG-Py.git

# check out the SHA-ID of the RMG-Py commit:
cd RMG-Py
sed -i -e 's/rmg_env/benchmark/g' environment_linux.yml
conda remove -n benchmark --all -y
conda env create -f environment_linux.yml # name will set by the name key in the environment yaml.
git checkout environment_linux.yml

export RMG_BENCHMARK=`pwd`
echo "benchmark2 version of RMG: "$RMG_BENCHMARK
git log --format=%H%n%cd -1

# compile RMG-Py:
source activate benchmark
make
source deactivate

cd ..

# clone benchmark RMG-database:
git clone https://github.com/ReactionMechanismGenerator/RMG-database.git
cd RMG-database
export RMGDB_BENCHMARK=`pwd`
echo "benchmark2 version of RMG-database: "$RMGDB_BENCHMARK
git log --format=%H%n%cd -1
cd ..

# prepare testing RMG-Py and RMG-db

# split the message on the '-' delimiter
IFS='-' read -a pieces <<< "$MESSAGE"

# check if the first part of the splitted string is the "rmgdb" string:
if [ "${pieces[0]}" == "rmgdb" ]; then
  # pushed commit is of RMG-database
  # message is of form: "rmgdb-SHA1"

  # pushed commit is of RMG-database:
  SHA1=${pieces[1]}
  echo "SHA1: "$SHA1

  # set the RMG environment variable:
  export RMG_TESTING=$RMG_BENCHMARK
  echo "test version of RMG (same as benchmark): "$RMG_TESTING

  cd $RMG_TESTING
  git log --format=%H%n%cd -1
  cd -

  conda remove -n testing --all -y
  conda create --name testing --clone benchmark

  # RMG-database for testing will be same
  echo "testing version of RMG-database: "$RMGDB_TESTING
  cd $RMGDB_TESTING
  git log --format=%H%n%cd -1
  cd -

  # return to parent directory:
  cd ..

else
  # message is of form: "SHA1"

  # pushed commit is of RMG-Py:
  SHA1=${pieces[1]}
  echo "SHA1: "$SHA1

  # RMG-Py for testing will be same
  echo "test version of RMG: "$RMG_TESTING
  cd $RMG_TESTING
  git log --format=%H%n%cd -1
  cd -

  export RMGDB_TESTING=$RMGDB_BENCHMARK
  echo "testing version of RMG-database: "$RMGDB_TESTING
  cd $RMGDB_TESTING
  git log --format=%H%n%cd -1
  cd -

  # return to parent directory:
  cd ..

fi

# go to RMG-tests folder:
cd $TRAVIS_BUILD_DIR
