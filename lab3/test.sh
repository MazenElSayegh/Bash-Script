source settings
set -x
tes=$(mysql -h ${MYSQLHOST} -u ${MYSQLUSER} -e "select * from ${MYSQLDB}.users")
echo "${tes}"
set +x