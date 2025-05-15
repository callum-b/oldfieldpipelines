#!/bin/bash
#!/bin/bash

## some parameters, would be nice to add opts to change them in the command line
ext=50 ## amount to extend peaks by to check for overlaps + gather read signal



opt="p"
peakfiles=()
graphfiles=()

while [ "$1" ]; do ## input files are given as arguments, like this: "multimapbw.sh peakfile1.peak peakfile2.peak ... peakfilen.peak :: bdgfile1.bdg bdgfile2.bdg ... bdgfilen.bdg "
    case $1 in 
        ::) opt="g";;
        *) if [ "$opt" = "p" ]; then peakfiles+=("$1")
           else                     graphfiles+=("$1")
           fi;;
    esac
    shift
done

printf "Peak files to process:\n" 1>&2
printf " <%s>\n" "${peakfiles[@]}" 1>&2
printf "\n" 1>&2
printf "Bedgraph files to process:\n" 1>&2
printf " <%s>\n" "${graphfiles[@]}" 1>&2
printf "\n" 1>&2

peaksum=$(echo ${peakfiles[@]} | md5sum)
graphsum=$(echo ${graphfiles[@]} | md5sum)

# printf "TOTO_$peaksum\n"
# printf "TOTO_$graphsum\n"

temp_pref="${peaksum%% *}_${graphsum%% *}"

# printf "TOTO_$temp_pref\n"


printf "Generating merged peak file...\n" 1>&2
# head -q ${peakfiles[@]} | sort -k1,1 -k2,2n > mmb_temp_${temp_pref}_peaks.bed ## for testing
cat ${peakfiles[@]} | sort -k1,1 -k2,2n > mmb_temp_${temp_pref}_peaks.bed
bedtools merge -d $ext -i mmb_temp_${temp_pref}_peaks.bed > mmb_temp_${temp_pref}_merged_peaks.bed
rm mmb_temp_${temp_pref}_peaks.bed
bedtools slop -g DATA/GENOMES/HG38_chrom_sizes.tsv -b $ext -i mmb_temp_${temp_pref}_merged_peaks.bed > mmb_temp_${temp_pref}_slopped_peaks.bed
rm mmb_temp_${temp_pref}_merged_peaks.bed

printf "Calculating intersect positions for individual vs merged peaks...\n" 1>&2

for a in "${peakfiles[@]}"; do
	arra=(${a//\// })
	aname=${arra[-1]}
	printf "$aname\n" 1>&2
	bedtools intersect -loj -a mmb_temp_${temp_pref}_slopped_peaks.bed -b $a | awk 'BEGIN {prev=-1} { if($2 != prev){ print $5; prev=$2 }}' > mmb_temp_${temp_pref}_intersect_slopped_$aname.bed # !! WARNING !!bedtools changed the format of their loj output, so this could be the wrong col. This script was developed with bedtools 2.31.1
done


printf "Mapping merged peak file to each bedgraph...\n" 1>&2

for b in "${graphfiles[@]}"; do
	arrb=(${b//\// })
	bname=${arrb[-1]}
	printf "$bname\n" 1>&2
	awk '!/^track/{print $1, $2, $3, ".", $4}' $b | SCRIPTS/bedmap_arm64 --prec 3 --unmapped-val 0 --wmean mmb_temp_${temp_pref}_slopped_peaks.bed /dev/stdin > mmb_temp_${temp_pref}_map_$bname.bed
done

printf "Concatenating outputs...\n" 1>&2

header="chr\tstart\tend"
for f in `ls mmb_temp_${temp_pref}_map_*bed`; do
	f_nopre=${f#"mmb_temp_${temp_pref}_map_"}
	f_arr=(${f_nopre//\./ })
	f_naked=${f_arr[0]}
	header="${header}\t${f_naked}"	
done

for f in `ls mmb_temp_${temp_pref}_intersect_slopped_*bed`; do 
        f_nopre=${f#"mmb_temp_${temp_pref}_intersect_slopped_"}
        f_arr=(${f_nopre//\./ })
        f_naked=${f_arr[0]}
        header="${header}\tstart_${f_naked}"
done


printf "$header\n"
paste mmb_temp_${temp_pref}_slopped_peaks.bed mmb_temp_${temp_pref}_map_*bed mmb_temp_${temp_pref}_intersect_slopped_*bed  

# rm mmb_temp_${temp_pref}_slopped_peaks.bed
# rm mmb_temp_${temp_pref}_map_*bed
# rm mmb_temp_${temp_pref}_intersect_slopped_*bed


printf "Done!\n" 1>&2
