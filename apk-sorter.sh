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
	elif [[ "${x}" =~ "ST=" ]]; then # e.g: Subject: ST=Portugal
		pattern="ST="
	elif [[ "${x}" =~ "OU=" ]]; then # e.g: Subject: OU=SKY
		pattern="OU="
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

		ret=0; mpkg=0
		local apk x arr
		apk="${1}"
	while read -r x; do
		if [[ "${x}" =~ (got error|got invalid) ]]; then
			echo -e ": ${apk}\n: ${x}"
			exit 1
		elif [[ "${x}" =~ "Package Name:" ]]; then
			arr[0]="${x/Package Name: /}"; mpkg="${arr[0]}"
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
		ret="${ret//[$'\\\/>\':<|!']/}"
		return 0
	fi
}


_help(){
cat <<EOF
Usage: apk-sorter <input> <output>
-i, Input directory or file.
-o, Output directory.
-b, Sort OBB files.
-g, Sort according to category.
-G, Do not sort without category.
-h, Show this message.
-V, Version info.
-v, Verbose mode.
EOF

}


_category(){
	[ "${category_mode}" = "1" ] || return 0
	unset ret
	local pkg file category result root sub err
	[ -n "${1}" ] && pkg="${1}" || return 1
	[ -n "${2}" ] && file="${2}" || return 1

	root00="Superuser-APK"
	root01="Stock-Alternative-APK"
	root02="Educational-APK"
	root03="Media-APK"
	root04="Games-APK"
	root05="Miscellaneous-APK"

	# root00
	root00sub01="Root-Granter-APK"
	root00sub02="System-Tuner-APK"
	root00sub03="Automation-APK"
	root00sub04="App-Manager-APK"
	root00sub05="App-Editor-APK"
	root00sub06="Emulators-APK"
	root00sub07="Xposed-APK"
	root00sub08="IDE-APK"
	root00sub09="Useful-Utils-APK"
	root00sub10="Diagnostic-APK"
	root00sub11="Malware-APK"

	# root02
	root02sub01="Books-APK"
	root02sub02="Scientific-APK"
	root02sub03="Religion-APK"
	root02sub04="Lingual-APK"
	root02sub05="Dictionary-APK"
	root02sub06="Translator-TTS-APK"

	# root03
	root03sub01="Media-Players-APK"
	root03sub02="Media-Editors-APK"
	root03sub03="Media-Download-APK"

	# root04
	root04sub01="Puzzle-Games-APK"

	# root05
	root05sub01="Android-Store-APK"
	root05sub02="Browsers-APK"
	root05sub03="Camera-Apps-APK"
	root05sub04="Cloud-Service-APK"
	root05sub05="Social-Media-APK"
	root05sub06="Commercial-APK"
	root05sub07="Navigation-APK"
	root05sub08="Shopping-APK"
	root05sub09="Services-APK"
	root05sub10="Security-APK"
	root05sub11="AI-APK"
	root05sub12="Office-Documents-APK"
	root05sub13="Files-Manager-APK"
	root05sub14="Files-Transfer-APK"
	root05sub15="Files-Editor-APK"
	root05sub16="Weather-APK"
	root05sub17="Stream-APK"
	root05sub18="Wallet-APK"
	root05sub19="Google-APK"

	_category_set(){
		grep -Fqm1 "${pkg}" "${file_category_index}" && return 1 || { echo "${category} ${pkg}" >>"${file_category_index}" && return 0 || return 2; }
	}

	_category_get(){
		result=$(grep -Fm1 "${pkg}" "${file_category_index}" | awk '{print $1}')
		root="${result:0:2}"; sub="${result:2}"; [ "${sub}" = "00" ] && unset sub
		[ -n "${root}" ] && { root="root${root}"; ret="${!root}"; } || return 1
		[ -n "${sub}" ] && { sub="${root}sub${sub}"; ret="${ret}/${!sub}"; }
		mkdir -p "${output}/${ret}"
	}

	_category_put(){
		result=$(unzip -l "${file}" 2>&1)

		if [[ "${mpkg}" =~ (com.google.|com.android.chrome|com.android.vending) ]]; then
			category="0519"
		elif [[ "${result}" =~ (META-INF/xposed/module.prop|assets/xposed_init) ]]; then
			category="0007"
		elif [[ "${mpkg}" =~ (chinese|japan) ]]; then
			category="0204"
		else
			unset category
		fi

		[ -n "${category}" ] && return 0 || return 1
	}



	if ! _category_get; then
		_category_put && _category_set && _category_get && err=0 || err=1
	else
		err=0
	fi

	if [ ${err} -eq 0 ]; then
		echo ": category: ${ret}/${pkg}"
		return 0
	else
		[ "${category_strict}" = "1" ] && { echo ": failed (type: ${mtype}): ${pkg}"; return 1; }
		return 0
	fi
}

_check(){
	local cmd f u
	export PATH+=:~/.apk-sorter
	[ -s "./categorized.txt" ] && file_category_index="./categorized.txt" || file_category_index=~/.apk-sorter/categorized.txt
	u=$(uname -a); u="${u,,}"

	if [[ "${u}" =~ (msys|cygwin|wsl|msvc) ]]; then
		f="https://github.com/delvinru/apk-info/releases/download/v1.0.13/apk-info-v1.0.13-x86_64-pc-windows-msvc.zip"
		cmd="pacman -S"
	elif [[ "${u}" =~ "gnu/linux" ]]; then
		f="https://github.com/delvinru/apk-info/releases/download/v1.0.13/apk-info-v1.0.13-x86_64-unknown-linux-musl.tar.gz"
		cmd="apt install -y"
	elif [[ "${u}" =~ "android" ]]; then
		f="https://github.com/delvinru/apk-info/releases/download/v1.0.13/apk-info-v1.0.13-aarch64-linux-android.tar.gz"
		cmd="apt install -y"
	else
		echo "unknown platform: ${u}"
		return 1
	fi

	if ! command -v apk-info >/dev/null; then
		mkdir -p ~/.apk-sorter
		curl -L "${f}" -o ~/.apk-sorter/tmp || return 1
		tar -xf ~/.apk-sorter/tmp -C ~/.apk-sorter/
		chmod +x ~/.apk-sorter/apk-info
	fi

	if ! command -v unzip >/dev/null; then
		${cmd} unzip || return 1
	fi

	if [ ! -s "${file_category_index}" ]; then
		f="https://raw.githubusercontent.com/mast3rz3ro/apk-sorter/refs/heads/main/categorized.txt"
		echo "fetching: categorized.txt"
		curl -L "${f}" -o "${file_category_index}" || return 1
	fi

}


_main()
{
	unset category_mode category_strict
	local input output sort_obb output_mode manifest category state mtype result num opt arr err x
	verbose_mode=0

	while getopts i:o:bgGVvh opt; do
		case "${opt}" in
			i) input="${OPTARG}";;
			o) output="${OPTARG}";;
			b) sort_obb="1";;
			g) category_mode="1";;
			G) category_mode="1"; category_strict="1";;
			v) verbose_mode="1";;
			h) _help; return 0;;
			V) echo "apk-sorter-v1.1.0"; return 0;;
			*) break;;
		esac
	done

	[ -z "${input}" ] && { _help; return 1; }

	[ -n "${output}" ] && output_mode=1 || output_mode=0
	([ ${output_mode} -eq 1 ] && [ ! -d "${output}" ]) && { echo "creating output dir: ${output}"; mkdir -p "${output}"; }


	while read -r x; do
		if [[ "${x}" =~ (\.apks$|\.apkm$|\.xapk$) ]]; then
			state=3; mtype="bundle-apk"
		elif [[ "${x}" =~ (\.obb$) ]]; then
			state=2; mtype="obb"
		elif [[ "${x}" =~ (\.apk$) ]]; then
			state=1; mtype="standalone"
		else
			echo "unexpected error: ${x}"
			return 1
		fi

		[ ${output_mode} -eq 1 ] || output="${x%/*}"

		if [ ${state} -eq 1 ] || [ ${state} -eq 3 ]; then
			if [ ${state} -eq 3 ]; then
				num=$(unzip -l "${x}" | grep -c "\.apk$")
				if [ ${num} -eq 1 ]; then
					echo ": Fixing: ${x}"
					arr=($(unzip -l "${x}" | grep "\.apk$")); result="${arr[3]}"
					unzip -qx "${x}" "${result}" -d "${output}" && rm "${x}"
					x="${output}/${result}"
				fi
			fi

			[ ${verbose_mode} -eq 1 ] && echo ": file: ${x}"
			_manifest "${x}" && { manifest="${ret}"; unset ret; } || continue
			echo ": ${manifest}.${x##*.}"
			_category "${mpkg}" "${x}" && { [ -n "${ret}"] && category="${ret}"; } || continue
			mv "${x}" "${output}/${category}/${manifest}.${x##*.}" || return 1
		elif [ ${state} -eq 2 ] && [ "${sort_obb}" = "1" ]; then
			result=$(echo "${x}" | grep -Po "main\.[^\.]*.\K.*" | sed "s/\.obb//")
			echo ": obb: ${result}.${x##*.}"
			_category "${result}" "${x}" && category="${ret}" || continue
			mv "${x}" "${output}/${category}/" || return 1
			continue
		fi

	done< <(find "${input}" -type f \( -name "*.apk" -or -name "*.apks" -or -name "*.xapk" -or -name "*.apkm" -or -name "*.obb" \))
}

_check || exit 1
_main "${@}"

