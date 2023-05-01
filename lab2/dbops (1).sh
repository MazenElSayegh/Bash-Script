source checker.sh

function authenticate {
	echo "Authentication.."
}

function querystudent {
	echo "Now query"
	echo -n "Enter student name to query GPA : "
	read NAME
	##We want to get line from datafile starts with NAME followed by :
	LINE=$(grep "^${NAME}:" datafile)
	if [ -z ${LINE} ]
	then
		echo "Error, student name ${NAME} not found"
	else
		GPA=$(echo ${LINE} | awk ' BEGIN { FS=":" } { print $2 } ')
		echo "GPA for ${NAME} is ${GPA}"
	fi
}

function insertstudent {
	echo "Inserting a new student"
	echo -n "Enter name : " 
	read NAME
	echo -n "Enter GPA : "
	read GPA
	### Before adding, we want to check GPA valid floating point or no
	checkFloatPoint $GPA
	if [ ${?} -eq 0 ]
	then
		echo "${NAME}:${GPA}" >> datafile
	else
		echo "Invalid GPA"
	fi
}

function deletestudent {
	echo "Deleting an existing student"
	echo -n "Enter student to delete : "
	read NAME
	##We want to get line from datafile starts with NAME followed by :
	LINE=$(grep "^${NAME}:" datafile)
	if [ -z ${LINE} ]
	then
        	echo "Error, student name ${NAME} not found"
	else
	##BEfore delete, print confirmation message to delete or no
		echo -n "Are you sure you want to delete ${NAME}? (y/n): "
       	 	read RESP
		if [ ${RESP} == "y" ]
		then
		##-v used to get lines DOES NOT contain regex
			grep -v "^${NAME}:" datafile > /tmp/datafile
			cp /tmp/datafile datafile
			rm /tmp/datafile
		fi
	fi
}

function updatestudent {
	echo "Updating an existing student"
	echo -n "Enter student name to update : "
        read NAME
	##We want to get line from datafile starts with NAME followed b>
        LINE=$(grep "^${NAME}:" datafile)
        if [ -z ${LINE} ]
        then
                echo "Error, student name ${NAME} not found"
        else
        	echo -n "Enter new GPA : "
        	read GPA
        ### Before adding, we want to check GPA valid floating point or no
       		checkFloatPoint $GPA
       		if [ ${?} -eq 0 ]
       		then
			OLDGPA=$(grep -n "^${NAME}:" "datafile" | cut -d ':' -f3)
			sed "s/${OLDGPA}/${GPA}/g" datafile
       		else
               		echo "Invalid GPA"
       		fi
	fi
}
