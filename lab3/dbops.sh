source checker.sh

##Function check if id exists or no
##Exit codes:
#	0: Success
#	1: not enough parameter
#	2: Not an integer
#	3: id exists

function checkID {
	[ ${#} -ne 1 ] && return 1
	checkInt ${1}
	[ ${?} -ne 0 ] && return 2
	RES=$(mysql -h ${MYSQLHOST} -u ${MYSQLUSER} -e "select * from ${MYSQLDB}.invdata where (id=${1})")
        [ ! -z "${RES}" ] && return 3
	return 0
}

##Function converts text in textfile to invdata and invdet tables in database
##Exit codes:
#	0: Success
#	1: invdata file not found
#	2: invdata not readable
#	3: invdet file not found
#	4: invdet not readable
#	5: Not authenticated


function convertTextToDB {
	echo "Convert text to database"

	if [ -z ${CURUSER} ] 
	then
		echo "Authenticate first"
		return 6
	fi
	
	checkFile "invdata"
    	[ ${?} -ne 0 ] && exit 1
    	checkRFile "invdata"
    	[ ${?} -ne 0 ] && exit 2

    	checkFile "invdet"
    	[ ${?} -ne 0 ] && exit 3
    	checkRFile "invdet"
    	[ ${?} -ne 0 ] && exit 4

##read invdata file and convert text to invdata table in database
	cat invdata | sed '1d' | while read line; do
        	local ID=$(echo ${line} | awk ' BEGIN { FS=":" } { print $1 } ')
        	local CUSTOMERNAME=$(echo ${line} | awk ' BEGIN { FS=":" } { print $2 } ')
        	local DATE=$(echo ${line} | awk ' BEGIN { FS=":" } { print $3 } ')
        	echo "insert into ${MYSQLDB}.invdata (id,customername,date) values (${ID},'${CUSTOMERNAME}','${DATE}')"
		mysql -h ${MYSQLHOST} -u ${MYSQLUSER} -e "insert into ${MYSQLDB}.invdata (id,customername,date) values (${ID},'${CUSTOMERNAME}','${DATE}')"
    	done
##read invdet file and convert text to invdet table in database
	cat invdet | sed '1d' | while read linedet; do
        	local SERIAL=$(echo ${linedet} | awk ' BEGIN { FS=":" } { print $1 } ')
        	local ID=$(echo ${linedet} | awk ' BEGIN { FS=":" } { print $2 } ')
        	local PRODID=$(echo ${linedet} | awk ' BEGIN { FS=":" } { print $3 } ')
		local QUANTITY=$(echo ${linedet} | awk ' BEGIN { FS=":" } { print $4 } ')
		local UNITPRICE=$(echo ${linedet} | awk ' BEGIN { FS=":" } { print $5 } ')
        	echo "insert into ${MYSQLDB}.invdet (serial,id,prodid,quantity,unitprice) values ('${SERIAL}',${ID},${PRODID},${QUANTITY},${UNITPRICE})"
		mysql -h ${MYSQLHOST} -u ${MYSQLUSER} -e "insert into ${MYSQLDB}.invdet (serial,id,prodid,quantity,unitprice) values ('${SERIAL}',${ID},${PRODID},${QUANTITY},${UNITPRICE})"
    	done
}


	
	

function authenticate {
	echo "Authentication.."
	CURUSER=""
	echo -n "Enter your username: "
	read USERNAME
	echo -n "Enter your password: "
	read -s PASSWORD
	### Start authentication. Query database for the username/password
	RES=$(mysql -h ${MYSQLHOST} -u ${MYSQLUSER} -e "select username from ${MYSQLDB}.users where (username='${USERNAME}') and (password=md5('${PASSWORD}'))")
	if [ -z "${RES}" ]
	then
		echo "Invalid credentials"
		return 1
	else
		CURUSER=${USERNAME}
		echo "Welcome ${CURUSER}"
	fi
	return 0
}



##Function, query a customer
##Exit
#	0: Success
#	1: Not authenticated
#	2: invalid id as an integer
#	3: id not exists
function queryinvoice {
	echo "Query"
	if [ -z ${CURUSER} ] 
	then
		echo "Authenticate first"
		return 1
	fi
	echo -n "Enter invoice id : "
        read INVOICEID
        checkInt ${INVOICEID}
        [ ${?} -ne 0 ] && echo "Invalid integer format" && return 2
        ##Check if the ID is already exists or no
        checkID ${INVOICEID}
        [ ${?} -eq 0 ] && echo "ID ${INVOICEID} not exists!" && return 3
	## We used -s to disable table format
	RES=$(mysql -h ${MYSQLHOST} -u ${MYSQLUSER} -s -e "select * from ${MYSQLDB}.invdata where (id=${INVOICEID})"| tail -1)
	ID=${INVOICEID}
	CUSTOMERNAME=$(echo "${RES}"| awk ' { print $2 } ')
	DATE=$(echo "${RES}"| awk ' { print $3 } ')
	echo "Invoice ID: ${ID}"
	echo "Invoice date : ${DATE}"
	echo "Customer name : ${CUSTOMERNAME}"
	NUMBEROFPRODUCTS=$(mysql -h ${MYSQLHOST} -u ${MYSQLUSER} -s -e "select COUNT(*) from ${MYSQLDB}.invdet where (id=${INVOICEID})" | tail -1)

	echo "Details: "
    	echo -e "Product ID\tQuantity\tunit price\tTotal product "
    	COUNTER=1
    	TOTAL=0
    	while [ ${NUMBEROFPRODUCTS} -ge ${COUNTER} ]
    	do
        PRODUCT=$(mysql -h ${MYSQLHOST} -u ${MYSQLUSER} -s -e "select * from ${MYSQLDB}.invdet where (id=${INVOICEID})" | sed -n "${COUNTER}p")
        
        local SERIAL=$(echo ${PRODUCT} | awk ' { print $1 } ')
        local INVID=$(echo ${PRODUCT} | awk ' { print $2 } ')
        local PRODID=$(echo ${PRODUCT} | awk ' { print $3 } ') 
        local QUANTITY=$(echo ${PRODUCT} | awk ' { print $4 } ')
        local PRICE=$(echo ${PRODUCT} | awk ' { print $5 } ')
        local PRODUCTTOTALPRICE=$(echo ${QUANTITY} \* ${PRICE} | bc)
        echo  -e "${PRODID}\t\t${QUANTITY}\t\t${PRICE}\t\t${PRODUCTTOTALPRICE} \t"
        COUNTER=$[${COUNTER} + 1]
        TOTAL=$[${PRODUCTTOTALPRICE} + ${TOTAL}]
    	done

    echo "==================================================="
    echo "Invoice total: ${TOTAL}"
    return 0
}

##Exit codes
#	0: Success
#	1: ID is not an integer
#	2: Total is not an integer
#	3: ID already exists
#  	4: PRODID is not valid
#  	5: QUANTITY is not valid
#  	6: PRICE is not valid
function insertcustomer {
	local OPT
	echo "Insert"
	echo "Query"
        if [ -z ${CURUSER} ]
        then
                echo "Authenticate first"
                return 1
        fi
	echo -n "Enter invoice id : "
	read INVOICEID
	checkInt ${INVOICEID}
	[ ${?} -ne 0 ] && echo "Invalid integer format" && return 1
	##Check if the ID is already exists or no
	checkID ${INVOICEID}
	[ ${?} -ne 0 ] && echo "ID ${INVOICEID} is already exists!!" && return 3
	echo -n "Enter invoice customer name : "
	read CUSTNAME
	echo -n "Enter invoice date : "
	read DATE

    echo -n "Enter serial : "
    read SERIAL

    echo -n "Enter product id : "
    read PRODID

	checkInt ${PRODID}
	[ ${?} -ne 0 ] && echo "Invalid integer format" && return 4

    echo -n "Enter product quantity : "
    read QUANTITY
	checkInt ${QUANTITY}
	[ ${?} -ne 0 ] && echo "Invalid integer format" && return 5

    echo -n "Enter product price : "
    read PRICE
	checkInt ${PRICE}
	[ ${?} -ne 0 ] && echo "Invalid integer format" && return 6
	echo -n "Save (y/n)"
	read OPT
	case "${OPT}" in
		"y")
			mysql -h ${MYSQLHOST} -u ${MYSQLUSER} -e "insert into ${MYSQLDB}.invdata (id,customername,date) values (${INVOICEID},'${CUSTNAME}','${DATE}')"
            		mysql -h ${MYSQLHOST} -u ${MYSQLUSER} -e "insert into ${MYSQLDB}.invdet (serial, id, prodid, quantity, unitprice) values ('${SERIAL}',${INVOICEID},${PRODID},${QUANTITY},${PRICE})"
			echo "Done .."
			;;
		"n")
			echo "Discarded."
			;;
		*)
			echo "Invalid option"
	esac
	return 0
}

function deletecustomer {
	echo "Delete"
	local OPT
        if [ -z ${CURUSER} ]
        then
                echo "Authenticate first"
                return 1
        fi
	echo -n "Enter invoice id : "
        read INVID
        checkInt ${INVID}
        [ ${?} -ne 0 ] && echo "Invalid integer format" && return 2
        ##Check if the ID is already exists or no
        checkID ${INVID}
        [ ${?} -eq 0 ] && echo "ID ${INVID} not exists!" && return 3
        ## We used -s to disable table format
        RES=$(mysql -h ${MYSQLHOST} -u ${MYSQLUSER} -s -e "select * from ${MYSQLDB}.invdata where (id=${INVID})"| tail -1)
        ID=${INVID}
        CUSTNAME=$(echo "${RES}"| awk ' { print $2 } ')
        DATE=$(echo "${RES}" | awk ' {  print $3 } ')
        echo "Details of invoice id ${INVID}"
        echo "invoice customer name : ${CUSTNAME}"
        echo "Invoice date : ${DATE}"
	echo -n "Delete (y/n)"
        read OPT
        case "${OPT}" in
                "y")
                        mysql -h ${MYSQLHOST} -u ${MYSQLUSER} -e "delete from ${MYSQLDB}.invdata where id=${INVID}"
                        echo "Done .."
                        ;;
                "n")
                        echo "not deleted."
                        ;;
                *)
                        echo "Invalid option"
        esac



	return 0
}

function updatecustomer {
	echo "Updating an existing customer"
	echo "Query"
        if [ -z ${CURUSER} ]
        then
                echo "Authenticate first"
                return 1
        fi
	return 0
}
