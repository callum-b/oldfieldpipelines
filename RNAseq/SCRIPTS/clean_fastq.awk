{
	 if (NR%4==1) {header=$0}
	         else if (NR%4==2) {sequence=$0}
			     else if (NR%4==3) {plus=$0}
			         else if (NR%4==0) {quality=$0; if ( length(sequence)>20 && length(sequence)==length(quality) ) {print header "\n" sequence "\n" plus "\n" quality}}
				 } 
