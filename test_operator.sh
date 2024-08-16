#! /bin/bash

# SPDX-FileCopyrightText: Tumelo Dlodlo (https://www.linkedin.com/in/tumelo-dlodlo/)
# SPDX-License-Identifier: GPL-3.0-or-later

# https://spdx.github.io/spdx-spec/v3.0/annexes/getting-started/

# @description Set the folder path of the library
# @arg $1 string $library_directory Directory path to where this file is located
declare library_directory="$1"
[[ -e "$library_directory" ]] || {
	declare script_file="$(realpath -e "$0")"
	library_directory="$(dirname "$script_file")"
}

# @description edit the attribute in the xml document
# @arg $1 string ${!attributes_filepath} Filepath that has the data to set, Data is in key value pairs.
#  	Feilds are delimited by ascii unit seperators
# 	Records are delimited by ascii record seperators
# 	@see https://en.wikipedia.org/wiki/C0_and_C1_control_codes#C0_controls

# @arg $2 string ${!xml_filepath} The xml document filepath to edit
# @stderr Required: Transform xml document
# @stderr Required: xml document
# @exitcode 1 error
# @stdout Edited xml document
# @exitcode 0 document is edited
function umoja·test_operator·set_xml_attribute() {
	# the attribute dictionary filepath. This attribute dictionary
	#+	will be set in the xml_filepath file
	local attributes_filepath=1

	# the xml document filepath
	local xml_filepath=2
	[[ -e "${!xml_filepath}" ]] || {
		umoja·test_operator·required_error "xml document"
		return 1
	}

	# xpath to the attribute is the key
	#+	first field in record
	local key=

	#  new attribute value for the key
	#+	second field in record
	local value=

	# third and later fields in record are ignored
	local ignore_other=

	# create stylesheet xml elements to edit the matched attribute in the xml document
	#+	- select the attribute by xpath (key)
	#+	- set the attribute to a value (value)
	# read the key, value from stdin records
	local -a match_attributes=()
	while IFS=$'' read -r -d $'' \
		key value \
		ignore_other
	do
		match_attributes+=('
			<!-- set the attribute -->
			<xsl:template match="'"$key"'">
				<xsl:attribute name="'"${key//*\@/}"'">'"$value"'</xsl:attribute>
			</xsl:template>
		')
	done <"${!attributes_filepath}"

	local set_attribute_stylesheet=
	# apply the stylesheet to the xml document
	#+	- then, on success, print the new xml document
	xsltproc \
		<(
			printf "%s\n" \
				'<?xml version="1.0" encoding="UTF-8"?>
				<xsl:stylesheet
					version="1.0"
					xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
					<xsl:output omit-xml-declaration="no" indent="yes"/>
					<xsl:strip-space elements="*" />

					'"${match_attributes[*]}"'

					<!--  identity template  -->
					<xsl:template match="@*|node()">
						<xsl:copy>
							<xsl:apply-templates select="@*|node()"/>
						</xsl:copy>
					</xsl:template>
				</xsl:stylesheet>'
 		) \
		"${!xml_filepath}" \
	&& {
		# success
		return 0
	}

	# return error
	#+	the stylesheet is errornously applied to the xml document
	umoja·test_operator·required_error "transform xml document"
	return 1
}

# @description Set the results for a specific test case
# @arg $1 string ${!cases_plan} File containing the test plan html table for all test cases
# @stdin read test case_id, case_result, case_tester from stdin
# 	Feilds are delimited by ascii unit seperators
# 	Records are delimited by ascii record seperators
# 	@see https://en.wikipedia.org/wiki/C0_and_C1_control_codes#C0_controls
# @stderr Required: test cases plan
# @stderr Required: case_id
# @stderr Required: case_result
# @stderr Required: case_tester
# @stderr Required: cases_plan
# @stderr Required: set arguments in the stylesheet used to update test case result
# @stderr Required: update the test case result
# @exitcode 1 Update of test case result failed
# @exitcode 0 Updated test case result
function umoja·test_operator·update_case_result() {
	# file containing the test plan html table
	#+	for all test cases
	local cases_plan=1
	[[ -z "${!cases_plan}" ]] \
		|| [[ -e "${!cases_plan}" ]] \
		|| {
			umoja·test_operator·required_error "test cases plan"
			return 1
		}

	# xsl file containing the stylesheet that is used to
	#+	update the test case result in the test cases plan
	#+	html table
	local update_case_result_stylesheet="$library_directory/update_case_result.xsl"

	# id of the current test case
	local case_id=
	# result of the current test case
	local case_result=
	# person who authored the test
	local case_tester=

	# first and second field in record
	local id{_name,}=
	# third field in record
	local key=
	# fourth field in record
	local value=
	# later fields in a read record are ignored
	local ignore_other=

	# read the test case_id, case_result, case_tester, cases_plan from stdin records
	while \
		IFS=$'' read -r -d $'' \
			id{_name,} \
			key value \
			ignore_other && {
				[[ -z "$case_id" ]] \
				|| [[ -z "$case_result" ]] \
				|| [[ -z "$case_tester" ]] \
				|| [[ -z "${!cases_plan}" ]]
			}
	do
		# trim whitespace
		id_name="$(umoja·test_operator·trim "$id_name")"
		id="$(umoja·test_operator·trim "$id")"
		key="$(umoja·test_operator·trim "$key")"
		value="$(umoja·test_operator·trim "$value")"

		# find start of test case collection
		#+	test case collection starts with case_id
		[[ "$id_name"=="case_id" ]] || continue
		case_id="$id"

		# copy the test case collection items
		case "$(printf "%s" "${key}")" in
			case_result)
				case_result="$value"
			;;

			case_tester)
				case_tester="$value"
			;;

			cases_plan)
				# ignore default cases plan if overriden on command line
				[[ -z "${!cases_plan}" ]] && {
					cases_plan="$value"
				}
			;;
		esac
	done

	# case_id is required
	[[ -z "$case_id" ]] && {
		umoja·test_operator·required_error "case_id"
		return 1
	}

	# case_result is required
	[[ -z "$case_result" ]] && {
		umoja·test_operator·required_error "case_result" "case_id" "$case_id"
		return 1
	}

	# case_tester is required
	[[ -z "$case_tester" ]] && {
		umoja·test_operator·required_error "case_tester" "case_id" "$case_id"
		return 1
	}

	# cases_plan is required
	[[ -e "${!cases_plan}" ]] || {
		umoja·test_operator·required_error "cases_plan" "case_id" "$case_id"
		return 1
	}

	# the $update_case_result_stylesheet has parameters:
	#+	- case_id
	#+	- case_result
	#+	- case_tester
	#+ 	the stylesheet is used to update the case result
	#+	in the test cases plan
	# set the case arguments in the stylesheet
	local updater_stylesheet=
	updater_stylesheet="$(mktemp)" && {
		umoja·test_operator·set_xml_attribute \
			<(
				umoja·test_operator·key_value \
					'//xsl:param[@name='"'case_id'"']/@select' \
					"'$case_id'"

				umoja·test_operator·key_value \
					'//xsl:param[@name='"'case_result'"']/@select' \
					"'$case_result'"

				umoja·test_operator·key_value \
					'//xsl:param[@name='"'case_tester'"']/@select' \
					"'$case_tester'"
			) \
			"$update_case_result_stylesheet" >"$updater_stylesheet"
	} || {
		# error
		#+	cannot set the case arguments in the stylesheet
		umoja·test_operator·required_error "set arguments in the stylesheet used to update test case results"
		return 1
	}


	# update the test case result in the test cases plan html table
	local updated_cases_plan=
	updated_cases_plan="$(mktemp)" && {
		# update command run by the current process
		local update_command='{
			# update content and save to a temporary file
			xsltproc \
				--html \
				"'"$updater_stylesheet"'" \
				"'"${!cases_plan}"'" >'"$updated_cases_plan"' \
			&& {
				# save the updated content by over writting
				#+	test cases plan file if the update was
				#+	successful
				cat '"$updated_cases_plan"' >'"${!cases_plan}"'
			}
		}'

		# allow one process at a time to edit the cases_plan
		#+	by locking the cases_plan
		flock \
			--exclusive "${!cases_plan}" \
			--command "$update_command"
	} || {
		umoja·test_operator·required_error "update the test case result"
		return 1
	}

	# success
	return 0
}

# @description Operations code to run test cases that have their own operations code
# @arg --plan <filepath> Filepath containing the test plan table for each test case
# @arg --cases <filepath> Filepath containing the list of filepaths delimited by newlines
# @arg --log <filepath> Filepath containing the logs for all test cases
# @stderr Required: --plan test cases plan filepath
# @stderr Required: --cases test cases list filepath
# @stderr Required: --log test cases log filepath
function umoja·test_operator() {
	# file containing the test plan table
	#+	for each test case
	local cases_plan=
	# file path to file containing tests
	local cases_list=
	# log file
	local cases_log=

	# positional parameter
	local positional_parameter=
	# get arguments
	for positional_parameter
	do
		case "$1" in
			--plan)
				shift && {
					cases_plan="$1"
				}
			;;

			--cases)
				shift && {
					cases_list="$1"
				}
			;;

			--log)
				shift && {
					cases_log="$1"
				}
			;;
		esac
		shift || break
	done

	# test cases plan file is required
	[[ -z "$cases_plan" ]] || {
		cases_plan="$(realpath "$cases_plan")"
	} || {
		umoja·test_operator·required_error "--plan test cases plan filepath"
		return 1
	}

	# test cases_list file is required
	[[ -e "$cases_list" ]] || {
		umoja·test_operator·required_error "--cases test cases list filepath"
		return 1
	}

	# test cases_log file is required
	[[ ! -z "$cases_log" ]] || {
		umoja·test_operator·required_error "--log test cases log filepath"
		return 1
	}

	# foreach test case file
	local test_case=
	while read -r test_case <"$cases_list"
	do
		# run the test case in isolation
		umoja·test_operator·interview_case \
			"$test_case" \
			>(
				# save the test result in the test cases plan file
				umoja·test_operator·update_case_result "$cases_plan"
			)
		# save logs
	done >>"$cases_log" 2>&1
}

# @description Query settings from the test case file then run the test case
# @arg $1 string ${!test_case} Test case file
# @arg $N string process to which interview results are sent
# @stdout cases[id=$(${!test_case} --case-id)]/interview_test_case ${!test_case}
# @stdout Required: executable test case
function umoja·test_operator·interview_case() {
	local test_case=1
	local process_list=2

	# @todo create interview container

	# @todo upload test case into interview container

	# @todo ask the test case what container it wants

	# @todo the test case responds with a operations script

	# @todo create new container from the operations script
	#+	in the interview container

	# @todo run the test case in the new container
	#+	while printing the results into the interview container

	# @todo read results from inteview container

	# @todo destroy both containers




	# make the test case file executable
	chmod u+x "${!test_case}" || {
		umoja·test_operator·required_error "executable test case"
		return 1
	}

	# run test file
	${!test_case} > >(
		# send the output to other processes as listed
		#+	from positional parameter 2 to the end
		tee "${@:$process_list}"
	)
}

# @description Show required error message
# @arg $1 ${argument} to trim
# @stdout Error record
# 	Feilds are delimited by ascii unit seperators
# 	Records are delimited by ascii record seperators
# 	@see https://en.wikipedia.org/wiki/C0_and_C1_control_codes#C0_controls
function umoja·test_operator·required_error() {
	local message=1
	local detail_list=2
	printf "%s\n" \
		"error: required message: ${!message} detail: ${@:$detail_list}" 1>&2
}

# @description Print key value pair
# @arg $1 ${key}
# @arg $2 ${value}
# @stdout Key value pair record
# 	Feilds are delimited by ascii unit seperators
# 	Records are delimited by ascii record seperators
# 	@see https://en.wikipedia.org/wiki/C0_and_C1_control_codes#C0_controls

function umoja·test_operator·key_value() {
	local key=1
	local value=2
	printf "%s\n" "${!key}${!value}"
}

# @description Trim leading and trailing whitespace
# @arg $1 ${argument} to trim
# @stdout Trimed value
function umoja·test_operator·trim() {
	shopt -s extglob
		# delete zero or more whitespaces from front of $1
		local argument="${1##+([[:space:]])}"
		shift
		# delete zero or more whitespaces from end of $1
		printf "%s" "${argument%%+([[:space:]])}"
	shopt -u extglob
}

