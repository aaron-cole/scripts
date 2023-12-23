


hostname="$(grep "<HOST_NAME>.*</HOST_NAME>" ./server.ckl | sed 's/^.*<HOST_NAME>//g' | sed 's/<\/HOST_NAME>//g')"

echo "Server,Vulnerability Number,Severity,Status,Finding Details,Comments" >> CSVFile.csv
#Read the ckl file

fnall()
{
while IFS= read -r line; do
	case "$line" in
	  *HOST_NAME*) HOSTNAME="$(echo "$line" | sed 's/^.*<HOST_NAME>//g' | sed 's/<\/HOST_NAME>//g')";;
		*\>V-*) VNUM="$(echo "$line" | sed 's/^.*<ATTRIBUTE_DATA>//g' | sed 's/<\/ATTRIBUTE_DATA>//g')";;
		*STATUS*) STATUS="$(echo "$line" | sed 's/^.*<STATUS>//g' | sed 's/<\/STATUS>//g')";;
		*FINDING_DETAILS*) FDINFO="$(echo "$line" | sed 's/^.*<FINDING_DETAILS>//g' | sed 's/<\/FINDING_DETAILS>//g' | sed 's/^=/ =/g')";;
	  *COMMENTS*) COMMENTS="$(echo "$line" | sed 's/^.*<COMMENTS>//g' | sed 's/<\/COMMENTS>//g' | sed 's/^=/ =/g')"
	  						echo "$HOSTNAME,$VNUM,$RISKCODE,$STATUS,$FDINFO,$COMMENTS" >> CSVFile.csv;;
	  *\>high*) RISKCODE="High";;
	  *\>medium*) RISKCODE="Medium";;
	  *\>low*) RISKCODE="Low";;
	 esac
done < $1
}

fnopen()
{
while IFS= read -r line; do
	case "$line" in
	  *HOST_NAME*) HOSTNAME="$(echo "$line" | sed 's/^.*<HOST_NAME>//g' | sed 's/<\/HOST_NAME>//g')";;
		*\>V-*) VNUM="$(echo "$line" | sed 's/^.*<ATTRIBUTE_DATA>//g' | sed 's/<\/ATTRIBUTE_DATA>//g')";;
		*STATUS*) STATUS="$(echo "$line" | sed 's/^.*<STATUS>//g' | sed 's/<\/STATUS>//g')";;
		*FINDING_DETAILS*) FDINFO="$(echo "$line" | sed 's/^.*<FINDING_DETAILS>//g' | sed 's/<\/FINDING_DETAILS>//g' | sed 's/^=/ =/g')";;
	  *COMMENTS*) COMMENTS="$(echo "$line" | sed 's/^.*<COMMENTS>//g' | sed 's/<\/COMMENTS>//g' | sed 's/^=/ =/g')"
	  						if [ $STATUS = "Open" ]; then
	  						 echo "$HOSTNAME,$VNUM,$RISKCODE,$STATUS,$FDINFO,$COMMENTS" >> CSVFile.csv
	  						fi;;
	  *\>high*) RISKCODE="High";;
	  *\>medium*) RISKCODE="Medium";;
	  *\>low*) RISKCODE="Low";;
	 esac
done < $1
}	




	