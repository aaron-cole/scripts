
VNUMUpdate="V-72259"
STOP=0

while IFS= read -r line; do

until [ "$STOP" -gt 4 ]; do
 	 
 	case "$line" in
	  *\>$VNUMUpdate*) STOP=1;;
		*STATUS*) if [ "$STOP" -eq 1 ]; then
							STATUS="$(echo "$line" | sed 's/^.*<STATUS>//g' | sed 's/<\/STATUS>//g')";;
		*FINDING_DETAILS*) FDINFO="$(echo "$line" | sed 's/^.*<FINDING_DETAILS>//g' | sed 's/<\/FINDING_DETAILS>//g' | sed 's/^=/ =/g')";;
	  *COMMENTS*) COMMENTS="$(echo "$line" | sed 's/^.*<COMMENTS>//g' | sed 's/<\/COMMENTS>//g' | sed 's/^=/ =/g')"
	  						if [ $STATUS = "Open" ]; then
	  						 echo "$HOSTNAME,$VNUM,$RISKCODE,$STATUS,$FDINFO,$COMMENTS" >> CSVFile.csv
	  						fi;;
	 esac
done < $1