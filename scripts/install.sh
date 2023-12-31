#!/bin/bash
#
# install
#
# This script must be run from the Android main directory.
# variscite/install must be at ~/q1000_100_build
#
# Variscite DART-MX8M patches for Android 10.0.0 2.3.0

set -e
#set -x

SCRIPT_NAME=${0##*/}
readonly SCRIPT_VERSION="0.1"

#### Exports Variables ####
#### global variables ####
readonly ABSOLUTE_FILENAME=$(readlink -e "$0")
readonly ABSOLUTE_DIRECTORY=$(dirname ${ABSOLUTE_FILENAME})
readonly SCRIPT_POINT=${ABSOLUTE_DIRECTORY}
readonly SCRIPT_START_DATE=$(date +%Y%m%d)
readonly ANDROID_DIR="${SCRIPT_POINT}/../../.."
readonly G_CROSS_COMPILER_PATH=${ANDROID_DIR}/prebuilts/gcc/linux-x86/aarch64/gcc-arm-8.3-2019.03-x86_64-aarch64-linux-gnu
readonly G_CROSS_COMPILER_ARCHIVE=gcc-arm-8.3-2019.03-x86_64-aarch64-linux-gnu.tar.xz
readonly G_VARISCITE_URL="https://variscite-public.nyc3.cdn.digitaloceanspaces.com"
readonly G_EXT_CROSS_COMPILER_LINK="${G_VARISCITE_URL}/Android/Android_iMX8_Q1000_230/gcc-arm-8.3-2019.03-x86_64-aarch64-linux-gnu.tar.xz"

readonly BASE_BRANCH_NAME="base_q10.0.0_2.3.0"

## git variables get from base script!
readonly _EXTPARAM_BRANCH="q10.0.0_2.3.0-ga-var01"

## dirs ##
readonly VARISCITE_PATCHS_DIR="${SCRIPT_POINT}/platform"
readonly VARISCITE_SH_DIR="${SCRIPT_POINT}/sh"
VENDOR_BASE_DIR=${ANDROID_DIR}/vendor/variscite


# print error message
# p1 - printing string
function pr_error() {
	echo ${2} "E: $1"
}

# print warning message
# p1 - printing string
function pr_warning() {
	echo ${2} "W: $1"
}

# print info message
# p1 - printing string
function pr_info() {
	echo ${2} "I: $1"
}

# print debug message
# p1 - printing string
function pr_debug() {
	echo ${2} "D: $1"
}

# test existing brang in git repo
# p1 - git folder
# p2 - branch name
function is_branch_exist()
{
	local D="${1}"
	local B="${2}"
	local B_found
	local HERE

	if [ \( ! -d "${D}" \) -o \( -z "${B}" \) ]; then
		echo false
		return
	fi

	HERE=${PWD}
	cd "${D}" > /dev/null

	# Check branch
	git branch 2>&1 > /dev/null
	if [ ${?} -ne 0 ]; then
		echo false
		cd ${HERE} > /dev/null
		return
	fi
	B_found=$(git branch | grep -w "${B}")
	if [ -z "${B_found}" ]; then
		echo false
	else
		echo true
	fi

	cd ${HERE} > /dev/null
	return
}

############### main code ##############
pr_info "Script version ${SCRIPT_VERSION} (g:20200401)"

# disable NXP kernel Android.mk
cd ${ANDROID_DIR} > /dev/null
mv vendor/nxp-opensource/kernel_imx/drivers/staging/greybus/tools/Android.mk vendor/nxp-opensource/kernel_imx/drivers/staging/greybus/tools/Android.mk__

cd ${ANDROID_DIR} > /dev/null
######## extended create repositories #######
pr_info "#########################"
pr_info "# Laird FW repositories #"
pr_info "#########################"

pr_info "clone ${VENDOR_BASE_DIR}/bcm_4343w_fw"
git clone https://github.com/varigit/bcm_4343w_fw.git ${VENDOR_BASE_DIR}/bcm_4343w_fw
cd ${VENDOR_BASE_DIR}/bcm_4343w_fw
git checkout 8081cd2bddb1569abe91eb50bd687a2066a33342 -b ${BASE_BRANCH_NAME}

pr_info "###############################"
pr_info "# Misc. external repositories #"
pr_info "###############################"

pr_info "clone ${VENDOR_BASE_DIR}/can-utils"
git clone https://github.com/linux-can/can-utils.git ${VENDOR_BASE_DIR}/can-utils
cd ${VENDOR_BASE_DIR}/can-utils > /dev/null
git checkout 791890542ac1ce99131f36435e72af5635afc2fa -b ${BASE_BRANCH_NAME}

pr_info "###########################"
pr_info "# Apply framework patches #"
pr_info "###########################"
cd ${VARISCITE_PATCHS_DIR} > /dev/null
git_array=$(find * -type d | grep '.git')
cd - > /dev/null

for _ddd in ${git_array}
do
	_git_p=$(echo ${_ddd} | sed 's/.git//g')
	cd ${ANDROID_DIR}/${_git_p}/ > /dev/null
	
	pr_info "Apply patches for this git: \"${_git_p}/\""
	
	git checkout -b ${_EXTPARAM_BRANCH} || {
		pr_warning "Branch ${_EXTPARAM_BRANCH} is present!"
	};

	git am ${VARISCITE_PATCHS_DIR}/${_ddd}/*

	cd - > /dev/null
done

pr_info "#######################"
pr_info "# Copy shell utilites #"
pr_info "#######################"
cp -r ${VARISCITE_SH_DIR}/* ${ANDROID_DIR}/

pr_info "#######################"
pr_info "# Copy ARM tool chain #"
pr_info "#######################"
# get arm toolchain
(( `ls ${G_CROSS_COMPILER_PATH} 2>/dev/null | wc -l` == 0 )) && {
	pr_info "Get and unpack cross compiler";
	cd ${ANDROID_DIR}/prebuilts/gcc/linux-x86/aarch64/
	wget ${G_EXT_CROSS_COMPILER_LINK}
	tar -xJf ${G_CROSS_COMPILER_ARCHIVE} \
		-C .
};

pr_info "#####################"
pr_info "# Done             #"
pr_info "#####################"

exit 0
