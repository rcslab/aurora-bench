prefix=$1
grep "requests per second" -R $prefix-* | awk '{print $1}' | python3 ave.py > $prefix.sum
