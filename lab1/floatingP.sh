#!/bin/bash
##Script on operations done n float numbers and validating them
##Parameters
	#First float number NUM1
	#Second float number NUM2
##Exit Codes
	# 0: Success
	# 1: Not enough parameters
	# 2: Division by zero
	# 3: NUM1 is not a float
	# 4: NUM2 is not a float
##Check for params
[ ${#} -ne 2 ] && exit 1

##Assign values to custom variables
NUM1=${1}
NUM2=${2}

##Check for float values
[ $(echo "${NUM1}" | grep -c "^\-\{0,1\}[0-9]*\.[0-9]*$") -ne 1 ] && exit 3
[ $(echo "${NUM2}" | grep -c "^\-\{0,1\}[0-9]*\.[0-9]*$") -ne 1 ] && exit 4

##Check for division by zero
[ ${2} == 0 ] || [ ${2} == "0.0" ]  && exit 2

##Perform division operation
DIV=$(echo " ${NUM1} / ${NUM2} " | bc)

##Perform division operation
ADD=$(echo " ${NUM1} + ${NUM2} " | bc)

##Perform division operation
SUB=$(echo " ${NUM1} - ${NUM2} " | bc)

##Perform division operation
MULT=$(echo " ${NUM1} * ${NUM2} " | bc)

##Prints result
echo "Division = ${DIV}"
echo "Multiplication = ${MULT}"
echo "Subtraction = ${SUB}"
echo "Addition = ${ADD}"

exit 0
