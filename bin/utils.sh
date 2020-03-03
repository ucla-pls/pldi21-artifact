function decomp () { 
  find $1 -name '*.class' | sort | xargs javap -p
}

function decomp_each () { 
  for file in $@; do
    decomp $file/input > $file/decomp.txt
  done
}

function progress_diff () { 
  first=$1; shift;
  for file in $@; do
    diff -u -U 1000000 $first/decomp.txt $file/decomp.txt > $first.diff
    first=$file
  done
}
