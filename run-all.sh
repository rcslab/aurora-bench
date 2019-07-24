#!/usr/local/bin/bash

source venv/bin/activate

SLS=$1 # Root dir of SLS project
SQL=$2 # Dir of SQL binaries
ITER=$3 # Num of iterations
MIN=$4 # Starting frequency
MAX=$5 # Largest Frequency
STEP=$6 # Every iteration what to add to the frequency


echo "Performing $3 Iterations on each benchmark"
echo $SLS $ITER $MIN $MAX $STEP
echo "\n"
echo "=========================================="
echo "Starting firefox"
echo "=========================================="
echo "\n"
cd firefox
bash benchmark-firefox.sh $SLS $ITER $MIN $MAX $STEP
cd ..

echo "\n"
echo "=========================================="
echo "Starting MySQL"
echo "=========================================="
echo "\n"
cd sql
bash benchmark-sql.sh $SQL $SLS $ITER $MIN $MAX $STEP
cd ..

echo "\n"
echo "=========================================="
echo "Starting Redis"
echo "=========================================="
echo "\n"
cd scripts
bash all.sh $SLS $3
cd ..

deactivate

