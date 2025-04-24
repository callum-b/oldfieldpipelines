BEGIN {
	OFS="\t"    
	root = gensub(".bedGraph","","g",ARGV[1])
	file = root ".bed"
	printf "" > file
    }

{ 
	nb+=1
	print $1, $2, $3, root "_" nb, $4, "."  >> file 
}
