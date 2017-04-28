#!/bin/bash
eg=$1
scoop_test=$2
set -e
if [ -z ${RMG_BENCHMARK+x} ]; then 
	echo "RMG variable is unset. Exiting..."
	exit 0
fi

export ORIGIN_PYTHONPATH=$PYTHONPATH
echo "Running $1 example"

###########
#BENCHMARK#
###########
# make folder for models generated by the benchmark version of RMG-Py/RMG-database:
export benchmark_tests=$DATA_DIR/tests/benchmark/${benchmark_py_sha}_${benchmark_db_sha}/
mkdir -p $benchmark_tests/rmg_jobs/$eg
rm -rf $benchmark_tests/rmg_jobs/$eg/*
cp $BASE_DIR/examples/rmg/$eg/input.py $benchmark_tests/rmg_jobs/$eg/input.py

source activate ${benchmark_env}

echo "benchmark version of RMG: "$RMG_BENCHMARK
export PYTHONPATH=$RMG_BENCHMARK:$ORIGIN_PYTHONPATH 

rm -rf ${RMG_BENCHMARK}/rmgpy/rmgrc
rmgrc="database.directory : "${RMGDB_BENCHMARK}/input/
echo $rmgrc >> ${RMG_BENCHMARK}/rmgpy/rmgrc

python $RMG_BENCHMARK/rmg.py $benchmark_tests/rmg_jobs/$eg/input.py > /dev/null

source deactivate
export PYTHONPATH=$ORIGIN_PYTHONPATH

#########
#TESTING#
#########
# make folder for models generated by the test version of RMG-Py and RMG-database:
export testing_tests=$DATA_DIR/tests/testing/${testing_py_sha}_${testing_db_sha}/
mkdir -p $testing_tests/rmg_jobs/$eg
rm -rf $testing_tests/rmg_jobs/$eg/*
cp $BASE_DIR/examples/rmg/$eg/input.py $testing_tests/rmg_jobs/$eg/input.py
source activate ${testing_env}
echo "test version of RMG: "$RMG_TESTING

export PYTHONPATH=$RMG_TESTING:$ORIGIN_PYTHONPATH 

rm -rf ${RMG_TESTING}/rmgpy/rmgrc
rmgrc="database.directory : "${RMGDB_TESTING}/input/
echo $rmgrc >> ${RMG_TESTING}/rmgpy/rmgrc

python $RMG_TESTING/rmg.py $testing_tests/rmg_jobs/$eg/input.py > /dev/null
export PYTHONPATH=$ORIGIN_PYTHONPATH
source deactivate

# compare both generated models
export check_tests=$DATA_DIR/tests/check/${testing_py_sha}_${testing_db_sha}/
mkdir -p $check_tests/rmg_jobs/$eg
rm -rf $check_tests/rmg_jobs/$eg/*
cd $check_tests/rmg_jobs/$eg

source activate ${benchmark_env}
export PYTHONPATH=$RMG_BENCHMARK:$ORIGIN_PYTHONPATH 

bash $BASE_DIR/check.sh $eg $benchmark_tests/rmg_jobs/$eg $testing_tests/rmg_jobs/$eg

export PYTHONPATH=$ORIGIN_PYTHONPATH
source deactivate

if [ $scoop_test == "yes" ]; then
	# make folder for models generated by the test version of RMG-Py and RMG-database, with scoop enabled:
	mkdir -p $testing_tests/rmg_jobs/$eg/scoop
	rm -rf $testing_tests/rmg_jobs/$eg/scoop/*
	cp $BASE_DIR/examples/rmg/$eg/input.py $testing_tests/rmg_jobs/$eg/scoop/input.py
	echo "Version of RMG running with SCOOP: $RMG"
	source activate ${testing_env}
	export PYTHONPATH=$RMG_TESTING:$ORIGIN_PYTHONPATH

	python -m scoop -n 1 $RMG_TESTING/rmg.py $testing_tests/rmg_jobs/$eg/scoop/input.py > /dev/null

	export PYTHONPATH=$ORIGIN_PYTHONPATH
	source deactivate

	# compare both generated models
	mkdir -p $check_tests/rmg_jobs/$eg/scoop
	cd $check_tests/rmg_jobs/$eg/scoop
	source activate ${benchmark_env}
	export PYTHONPATH=$RMG_BENCHMARK:$ORIGIN_PYTHONPATH 

	bash $BASE_DIR/check.sh $eg $benchmark_tests/rmg_jobs/$eg $testing_tests/rmg_jobs/$eg/scoop

	export PYTHONPATH=$ORIGIN_PYTHONPATH
	source deactivate
fi

echo "$eg: TEST JOB COMPLETE"

