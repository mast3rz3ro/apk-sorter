#!/bin/bash


_manifest()
{
_signtrue()
{
		local x f y pattern; x="${1}"; f="${2}"
		x="${x/Subject: /,},EOF" # e.g: Subject: CN=chuyb-re
		x="${x/ O=/,O=}"; x="${x/ L=/,L=}" # e.g: Subject: CN=Amazon Services LLC,OU=Java Object Signing O=Amazon Services LLC L=Las Vegas,ST=Nevada C=US
	if [[ "${x}" =~ "O=Unknown" ]]; then
		pattern="CN="
	elif [[ "${x}" =~ "O=" ]] && [[ ! "${x}" =~ "O=/" ]]; then # e.g: Subject: C=/,ST=/,L=/,O=/,OU=/,CN=mirukurusan
		pattern="O="
	elif [[ "${x}" =~ "CN=" ]] && [[ ! "${x}" =~ "CN=/" ]]; then
		pattern="CN="
	elif [[ "${x}" =~ "C=" ]] && [[ ! "${x}" =~ "C=/" ]]; then # e.g: Subject: C=ES
		pattern="C="
	else
		echo "target file: ${f}"
		echo "Unexpected signtrue comment:"
		declare -p x
		exit 1
	fi
		#declare -p pattern x
	while read -d "," y; do
		[[ "${y}" =~ "${pattern}" ]] && { arr[7]="${y/${pattern}/}"; return 0; }
	done< <(echo "${x}")
	return 1
}

		ret=0
		local apk x arr
		apk="${1}"
	while read -r x; do
		if [[ "${x}" =~ (got error|got invalid) ]]; then
			echo -e ": ${apk}\n: ${x}"
			exit 1
		elif [[ "${x}" =~ "Package Name:" ]]; then
			arr[0]="${x/Package Name: /}"
		elif [[ "${x}" =~ "Main Activity:" ]]; then
			arr[1]="${x/Main Activity: /}"
		elif [[ "${x}" =~ "Min SDK Version:" ]]; then
			arr[2]="${x/Min SDK Version: /}"
		elif [[ "${x}" =~ "Target SDK Version:" ]]; then
			arr[3]="${x/Target SDK Version: /}"
		elif [[ "${x}" =~ "Application Label:" ]]; then
			arr[4]="${x/Application Label: /}"
		elif [[ "${x}" =~ "Version Name:" ]]; then
			arr[5]="${x/Version Name: /}"
			arr[5]="${arr[5]// /}" # e.g: Tor Browser "15.0.19 "
		elif [[ "${x}" =~ "Version Code:" ]]; then
			arr[6]="${x/Version Code: /}"
		elif [[ "${x}" =~ "Subject:" ]]; then
			#declare -p x
			_signtrue "${x}" "${apk}"
		elif [[ "${x}" =~ "SHA256 fingerprint:" ]]; then
			x="${x/SHA256 fingerprint: /}"; x="${x/  SHA256 fingerprint: /}"
			arr[8]="${x:0:1}${x: -1}"; break
		fi
	done< <(apk-info show -s "${apk}" 2>&1)

		# Normal: Reddit_v2026.33.0(2633001)_9f(reddit Inc.).apks
		# Split: split_com.reddit.frontpage_config.ar_2633001.apk
		# some apps stores "Main Activity:" in other split
	if [ "${arr[0]}/-" = "${arr[1]}" ] && [ "${arr[4]}" = "-" ]; then
		arr[3]=$(apk-info axml "${apk}" | tr -d " " | grep -Po '^split="\K[^"]*')
		ret="split_${arr[0]}_${arr[3]}_${arr[6]}"
	else
		ret="${arr[4]}_v${arr[5]}(${arr[6]})_${arr[8]}(${arr[7]})"
		ret="${ret//[$'\\\/>\':<']/}"
		return 0
	fi
}


_help(){
cat <<EOF
Usage: apk-sorter <input> <output>
-i, Input directory or file.
-o, Output directory.
-h, Show this message.
-v, Version info.
EOF

}


_check(){
	local f u
	export PATH+=:~/.apk-sorter

	if command -v apk-info >/dev/null; then
		return 0
	fi

	u=$(uname -a); u="${u,,}"

	if [[ "${u}" =~ (msys|cygwin|wsl|msvc) ]]; then
		f="https://github.com/delvinru/apk-info/releases/download/v1.0.13/apk-info-v1.0.13-x86_64-pc-windows-msvc.zip"
	elif [[ "${u}" =~ "gnu/linux" ]]; then
		f="https://github.com/delvinru/apk-info/releases/download/v1.0.13/apk-info-v1.0.13-x86_64-unknown-linux-musl.tar.gz"
	elif [[ "${u}" =~ "android" ]]; then
		f="https://github.com/delvinru/apk-info/releases/download/v1.0.13/apk-info-v1.0.13-aarch64-linux-android.tar.gz"
	else
		echo "unknown platform: ${u}"
		return 1
	fi

	mkdir -p ~/.apk-sorter
	curl -L "${f}" -o ~/.apk-sorter/tmp || return 1
	tar -xf ~/.apk-sorter/tmp -C ~/.apk-sorter/
	chmod +x ~/.apk-sorter/apk-info
}


_main()
{
	local input output state opt x

	while getopts i:o:vh opt; do
		case "${opt}" in
			i) input="${OPTARG}";;
			o) output="${OPTARG}";;
			h) _help; return 0;;
			v) echo "apk-sorter_v1.0.0"; return 0;;
			*) break;;
		esac
	done

	[ -z "${input}" ] && { _help; return 1; }

	[ -z "${output}" ] && { [ -d "${input%/*}" ] && output="${input%/*}" || output="./"; }
	[ -d "${output}" ] || { echo "creating output dir: ${output}"; mkdir -p "${output}"; }

	while read -r x; do
		if [[ "${x}" =~ (\.apks$|\.apkm$|\.xapk$) ]]; then
			state=3
		elif [[ "${x}" =~ (\.obb$) ]]; then
			state=2
		elif [[ "${x}" =~ (\.apk$) ]]; then
			state=1
		else
			echo "unexpected error: ${x}"
			return 1
		fi

		if [ ${state} -eq 3 ]; then
			_manifest "${x}" || continue
			apk-info repack "${x}" -o "${output}/${ret}.${x##*.}" && rm "${x}" || return 1

		elif [ ${state} -eq 2 ]; then
			echo ": obb: ${x}"
			mv "${x}" "${output}" || return 1
			continue

		elif [ ${state} -eq 1 ]; then
			_manifest "${x}" || continue
			echo ": ${ret}.${x##*.}"
			mv "${x}" "${output}/${ret}.apk" || return 1

		fi
	done< <(find ${input} -type f \( -name "*.apk" -or -name "*.apks" -or -name "*.xapk" -or -name "*.apkm" -or -name "*.obb" \))
}

_check || exit 1
_main "${@}"

