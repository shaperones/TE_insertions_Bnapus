#!/bin/bash

in_dir=$1
out_dir=$2
cohortname=$3
famName=$4
shift 4
fqName=( "$@" )

indNB=${#fqName[@]}
echo -e "$cohortname\t$indNB"
anyinsertion=0

cd $out_dir/

if [ -e interbed.intersect.$famName.$cohortname.e ]
then
	rm -f *.e
	rm *.o*
	rm *.sh

fi

echo '#!/bin/sh' > tampon.intersect.$famName.$cohortname.sh 
if [ $indNB -gt 1 ]; then
	echo -n "multiIntersectBed -i " >> tampon.intersect.$famName.$cohortname.sh #-header 
else
	echo -n "cp " >> tampon.intersect.$famName.$cohortname.sh #-header
fi

for (( fosmid=0; fosmid<$indNB; fosmid++ ))  
do

	filename=${fqName[$fosmid]}
	if [ -s $famName.$filename-insertion-sites.sort.bed ] #check .bed file exists
	then
		anyinsertion=1
		echo -n "$famName.$filename-insertion-sites.sort.bed " >> tampon.intersect.$famName.$cohortname.sh
	fi
done

# cd $out_dir
if [ $anyinsertion -gt 0 ]
then
	if [ $indNB -gt 1 ]; then
		echo -n "-names " >> tampon.intersect.$famName.$cohortname.sh

		for (( fosmid=0; fosmid<$indNB; fosmid++ ))  
		do
			filename=${fqName[$fosmid]}
			if [[ -s $famName.$filename-insertion-sites.sort.bed ]] #check .bed file exists
			then
				echo -n "$filename " >> tampon.intersect.$famName.$cohortname.sh
			fi
		
		done

		echo " > $famName.$cohortname-intersect.bed " >> tampon.intersect.$famName.$cohortname.sh
	else
		echo -e " $famName.$cohortname-intersect.bed \n" >> tampon.intersect.$famName.$cohortname.sh
		echo "awk -i inplace 'BEGIN{OFS=\"\t\"} {\$4=\"1\"; \$5=\"1\"; \$6=\"1\"; print}' \"$famName.$cohortname-intersect.bed\"" >> tampon.intersect.$famName.$cohortname.sh
	fi

	chmod u+x $out_dir/tampon.intersect.$famName.$cohortname.sh
	command="$out_dir/tampon.intersect.$famName.$cohortname.sh > $out_dir/interbed.intersect.$famName.$cohortname.out 2> $out_dir/interbed.intersect.$famName.$cohortname.e &"
	nohup $command > $out_dir/tampon.intersect.$famName.$cohortname.log &
	latest_id=$!
	
	echo "Intersect bed $famName.$cohortname submitted: $latest_id"
else
	echo -en "no putative insertion detected\n"
	echo '' > $famName.$cohortname-intersect.bed

fi

