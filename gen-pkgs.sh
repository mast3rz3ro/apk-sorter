



	echo -n>"./result.log"
for x in ${1}/*; do
	p=$(apk-info show "$x" | grep -Po "Package Name: \K.*")
	echo "${2} ${p}" | tee -a "./result.log"
done
