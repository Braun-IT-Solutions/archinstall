SCRIPT_PATH=$(dirname "$0")
cd $SCRIPT_PATH
source ./util.sh

FILES=("util.sh" "luks-temp.key")


IFS=$'\n' 
read -r -d '' -a PERMISSIONS < <(stat -c "%A %U %G %n" "${FILES[@]}")

echo "${PERMISSIONS[0]}"
echo "${PERMISSIONS[1]}"

printf '%s\n' "${PERMISSIONS[@]}"




# IFS='\n'
# #PERMISSIONS=$(ls -al "${FILES[@]}" | cut -d' ' -f1,3,4,9)
# PERMISSIONS=$(stat -c "%A %U %G %n" "${FILES[@]}")
# echo ${PERMISSIONS}