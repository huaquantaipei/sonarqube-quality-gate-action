#!/usr/bin/env bash

source "$(dirname "$0")/common.sh"

if [[ -z "${SONAR_TOKEN}" ]]; then
  echo "Set the SONAR_TOKEN env variable."
  exit 1
fi

if [[ -z "${SONAR_PROJECT_KEY}" ]]; then
  echo "Set the SONAR_PROJECT_KEY env variable."
  exit 1
fi

metadataFile="$1"

if [[ ! -f "$metadataFile" ]]; then
   echo "$metadataFile does not exist."
   exit 1
fi

if [[ ! -z "${SONAR_HOST_URL}" ]]; then
   serverUrl="${SONAR_HOST_URL%/}"
   ceTaskUrl="${SONAR_HOST_URL%/}/api$(sed -n 's/^ceTaskUrl=.*api//p' "${metadataFile}")"
else
   serverUrl="$(sed -n 's/serverUrl=\(.*\)/\1/p' "${metadataFile}")"
   ceTaskUrl="$(sed -n 's/ceTaskUrl=\(.*\)/\1/p' "${metadataFile}")"
fi

if [ -z "${serverUrl}" ] || [ -z "${ceTaskUrl}" ]; then
  echo "Invalid report metadata file."
  exit 1
fi

if [[ -n "${SONAR_ROOT_CERT}" ]]; then
  echo "Adding custom root certificate to ~/.curlrc"
  rm -f /tmp/tmpcert.pem
  echo "${SONAR_ROOT_CERT}" > /tmp/tmpcert.pem
  echo "--cacert /tmp/tmpcert.pem" >> ~/.curlrc
fi

task="$(curl --location --location-trusted --max-redirs 10  --silent --fail --show-error --user "${SONAR_TOKEN}": "${ceTaskUrl}")"
status="$(jq -r '.task.status' <<< "$task")"

until [[ ${status} != "PENDING" && ${status} != "IN_PROGRESS" ]]; do
    printf '.'
    sleep 5
    task="$(curl --location --location-trusted --max-redirs 10 --silent --fail --show-error --user "${SONAR_TOKEN}": "${ceTaskUrl}")"
    status="$(jq -r '.task.status' <<< "$task")"
done
printf '\n'

analysisId="$(jq -r '.task.analysisId' <<< "${task}")"
qualityGateUrl="${serverUrl}/api/qualitygates/project_status?analysisId=${analysisId}"
qualityGateStatus="$(curl --location --location-trusted --max-redirs 10 --silent --fail --show-error --user "${SONAR_TOKEN}": "${qualityGateUrl}" | jq -r '.projectStatus.status')"

qualityGateStatus_reliability_rating="$(curl --location --location-trusted --max-redirs 10 --silent --fail --show-error --user "${SONAR_TOKEN}": "${qualityGateUrl}" | jq -r '.projectStatus.conditions[0].status')"
qualityGateStatus_reliability_rating_actualValue="$(curl --location --location-trusted --max-redirs 10 --silent --fail --show-error --user "${SONAR_TOKEN}": "${qualityGateUrl}" | jq -r '.projectStatus.conditions[0].actualValue')"
qualityGateStatus_security_rating="$(curl --location --location-trusted --max-redirs 10 --silent --fail --show-error --user "${SONAR_TOKEN}": "${qualityGateUrl}" | jq -r '.projectStatus.conditions[1].status')"
qualityGateStatus_security_rating_actualValue="$(curl --location --location-trusted --max-redirs 10 --silent --fail --show-error --user "${SONAR_TOKEN}": "${qualityGateUrl}" | jq -r '.projectStatus.conditions[1].actualValue')"
qualityGateStatus_blocker_violations="$(curl --location --location-trusted --max-redirs 10 --silent --fail --show-error --user "${SONAR_TOKEN}": "${qualityGateUrl}" | jq -r '.projectStatus.conditions[4].status')"
qualityGateStatus_blocker_violations_actualValue="$(curl --location --location-trusted --max-redirs 10 --silent --fail --show-error --user "${SONAR_TOKEN}": "${qualityGateUrl}" | jq -r '.projectStatus.conditions[4].actualValue')"
qualityGateStatus_critical_violations="$(curl --location --location-trusted --max-redirs 10 --silent --fail --show-error --user "${SONAR_TOKEN}": "${qualityGateUrl}" | jq -r '.projectStatus.conditions[7].status')"
qualityGateStatus_critical_violations_actualValue="$(curl --location --location-trusted --max-redirs 10 --silent --fail --show-error --user "${SONAR_TOKEN}": "${qualityGateUrl}" | jq -r '.projectStatus.conditions[7].actualValue')"
qualityGateStatus_major_violations="$(curl --location --location-trusted --max-redirs 10 --silent --fail --show-error --user "${SONAR_TOKEN}": "${qualityGateUrl}" | jq -r '.projectStatus.conditions[9].status')"
qualityGateStatus_major_violations_actualValue="$(curl --location --location-trusted --max-redirs 10 --silent --fail --show-error --user "${SONAR_TOKEN}": "${qualityGateUrl}" | jq -r '.projectStatus.conditions[9].actualValue')"
qualityGateStatus_minor_violations="$(curl --location --location-trusted --max-redirs 10 --silent --fail --show-error --user "${SONAR_TOKEN}": "${qualityGateUrl}" | jq -r '.projectStatus.conditions[10].status')"
qualityGateStatus_minor_violations_actualValue="$(curl --location --location-trusted --max-redirs 10 --silent --fail --show-error --user "${SONAR_TOKEN}": "${qualityGateUrl}" | jq -r '.projectStatus.conditions[8].actualValue')"
qualityGateStatus_line_coverage="$(curl --location --location-trusted --max-redirs 10 --silent --fail --show-error --user "${SONAR_TOKEN}": "${qualityGateUrl}" | jq -r '.projectStatus.conditions[10].status')"
qualityGateStatus_line_coverage_actualValue="$(curl --location --location-trusted --max-redirs 10 --silent --fail --show-error --user "${SONAR_TOKEN}": "${qualityGateUrl}" | jq -r '.projectStatus.conditions[8].actualValue')"


qualityGateStatus_code_smells="$(curl --location --location-trusted --max-redirs 10 --silent --fail --show-error --user "${SONAR_TOKEN}": "${qualityGateUrl}" | jq -r '.projectStatus.conditions[6].status')"
qualityGateStatus_code_smells_actualValue="$(curl --location --location-trusted --max-redirs 10 --silent --fail --show-error --user "${SONAR_TOKEN}": "${qualityGateUrl}" | jq -r '.projectStatus.conditions[6].actualValue')"
qualityGateStatus_new_code_smells="$(curl --location --location-trusted --max-redirs 10 --silent --fail --show-error --user "${SONAR_TOKEN}": "${qualityGateUrl}" | jq -r '.projectStatus.conditions[12].status')"
qualityGateStatus_new_code_smells_actualValue="$(curl --location --location-trusted --max-redirs 10 --silent --fail --show-error --user "${SONAR_TOKEN}": "${qualityGateUrl}" | jq -r '.projectStatus.conditions[12].actualValue')"

qualityGateStatus_bugs="$(curl --location --location-trusted --max-redirs 10 --silent --fail --show-error --user "${SONAR_TOKEN}": "${qualityGateUrl}" | jq -r '.projectStatus.conditions[5].status')"
qualityGateStatus_bugs_actualValue="$(curl --location --location-trusted --max-redirs 10 --silent --fail --show-error --user "${SONAR_TOKEN}": "${qualityGateUrl}" | jq -r '.projectStatus.conditions[5].actualValue')"
qualityGateStatus_new_bugs="$(curl --location --location-trusted --max-redirs 10 --silent --fail --show-error --user "${SONAR_TOKEN}": "${qualityGateUrl}" | jq -r '.projectStatus.conditions[11].status')"
qualityGateStatus_new_bugs_actualValue="$(curl --location --location-trusted --max-redirs 10 --silent --fail --show-error --user "${SONAR_TOKEN}": "${qualityGateUrl}" | jq -r '.projectStatus.conditions[11].actualValue')"



dashboardUrl=${serverUrl}
analysisResultMsg="Detailed information can be found at: ${dashboardUrl}"

if [[ ${qualityGateStatus} == "OK" ]]; then
   set_output "quality-gate-status" "PASSED"
   success "Quality Gate has PASSED."
elif [[ ${qualityGateStatus} == "WARN" ]]; then
   set_output "quality-gate-status" "WARN"
   warn "Warnings on Quality Gate.${reset}\n\n${analysisResultMsg}"
   endoferror ""
elif [[ ${qualityGateStatus} == "ERROR" ]]; then

   set_output "quality-gate-status" "FAILED"
   fail "Quality Gate has FAILED.${reset} ${analysisResultMsg}"

   title "Overall Code："
   #########################################################################################
   if [[ ${qualityGateStatus_reliability_rating} == "ERROR" ]]; then
       set_output "quality-gate-code-smells-status" "FAILED"
       fail "Reliability rating :${reset} ${qualityGateStatus_reliability_rating_actualValue}"
   elif [[ ${qualityGateStatus_reliability_rating} == "WARN" ]]; then
       set_output "quality-gate-code-smells-status" "WARN"
       warn "Reliability rating :${reset} ${qualityGateStatus_reliability_rating_actualValue}"
   elif [[ ${qualityGateStatus_reliability_rating} == "OK" ]]; then
       set_output "quality-gate-code-smells-status" "OK"
       success "Reliability rating :${reset} ${qualityGateStatus_reliability_rating_actualValue}"
   fi
   #########################################################################################

   if [[ ${qualityGateStatus_security_rating} == "ERROR" ]]; then
       set_output "quality-gate-code-smells-status" "FAILED"
       fail "Security rating :${reset} ${qualityGateStatus_security_rating_actualValue}"
   elif [[ ${qualityGateStatus_security_rating} == "WARN" ]]; then
       set_output "quality-gate-code-smells-status" "WARN"
       warn "Security rating :${reset} ${qualityGateStatus_security_rating_actualValue}"
   elif [[ ${qualityGateStatus_security_rating} == "OK" ]]; then
       set_output "quality-gate-code-smells-status" "OK"
       success "Security rating :${reset} ${qualityGateStatus_security_rating_actualValue}"
   fi
   #########################################################################################

   if [[ ${qualityGateStatus_blocker_violations} == "ERROR" ]]; then
       set_output "quality-gate-code-smells-status" "FAILED"
       fail "Blocker violations :${reset} ${qualityGateStatus_blocker_violations_actualValue}"
   elif [[ ${qualityGateStatus_blocker_violations} == "WARN" ]]; then
       set_output "quality-gate-code-smells-status" "WARN"
       warn "Blocker violations :${reset} ${qualityGateStatus_blocker_violations_actualValue}"
   elif [[ ${qualityGateStatus_blocker_violations} == "OK" ]]; then
       set_output "quality-gate-code-smells-status" "OK"
       success "Blocker violations :${reset} ${qualityGateStatus_blocker_violations_actualValue}"
   fi
   #########################################################################################

   if [[ ${qualityGateStatus_critical_violations} == "ERROR" ]]; then
       set_output "quality-gate-code-smells-status" "FAILED"
       fail "Critical violations :${reset} ${qualityGateStatus_critical_violations_actualValue}"
   elif [[ ${qualityGateStatus_critical_violations} == "WARN" ]]; then
       set_output "quality-gate-code-smells-status" "WARN"
       warn "Critical violations :${reset} ${qualityGateStatus_critical_violations_actualValue}"
   elif [[ ${qualityGateStatus_critical_violations} == "OK" ]]; then
       set_output "quality-gate-code-smells-status" "OK"
       success "Critical violations :${reset} ${qualityGateStatus_critical_violations_actualValue}"
   fi
   #########################################################################################

   if [[ ${qualityGateStatus_major_violations} == "ERROR" ]]; then
       set_output "quality-gate-code-smells-status" "FAILED"
       fail "Major violations :${reset} ${qualityGateStatus_major_violations_actualValue}"
   elif [[ ${qualityGateStatus_major_violations} == "WARN" ]]; then
       set_output "quality-gate-code-smells-status" "WARN"
       warn "Major violations :${reset} ${qualityGateStatus_major_violations_actualValue}"
   elif [[ ${qualityGateStatus_major_violations} == "OK" ]]; then
       set_output "quality-gate-code-smells-status" "OK"
       success "Major violations :${reset} ${qualityGateStatus_major_violations_actualValue}"
   fi
   #########################################################################################

   if [[ ${qualityGateStatus_minor_violations} == "ERROR" ]]; then
       set_output "quality-gate-code-smells-status" "FAILED"
       fail "Minor violations :${reset} ${qualityGateStatus_minor_violations_actualValue}"
   elif [[ ${qualityGateStatus_minor_violations} == "WARN" ]]; then
       set_output "quality-gate-code-smells-status" "WARN"
       warn "Minor violations :${reset} ${qualityGateStatus_minor_violations_actualValue}"
   elif [[ ${qualityGateStatus_minor_violations} == "OK" ]]; then
       set_output "quality-gate-code-smells-status" "OK"
       success "Minor violations :${reset} ${qualityGateStatus_minor_violations_actualValue}"
   fi
   #########################################################################################
   if [[ ${qualityGateStatus_line_coverage} == "ERROR" ]]; then
       set_output "quality-gate-code-smells-status" "FAILED"
       fail "Line coverage :${reset} ${qualityGateStatus_line_coverage_actualValue}"
   elif [[ ${qualityGateStatus_line_coverage} == "WARN" ]]; then
       set_output "quality-gate-code-smells-status" "WARN"
       warn "Line coverage :${reset} ${qualityGateStatus_line_coverage_actualValue}"
   elif [[ ${qualityGateStatus_line_coverage} == "OK" ]]; then
       set_output "quality-gate-code-smells-status" "OK"
       success "Line coverage :${reset} ${qualityGateStatus_line_coverage_actualValue}"
   fi
   #########################################################################################
   if [[ ${qualityGateStatus_code_smells} == "ERROR" ]]; then
       set_output "quality-gate-code-smells-status" "FAILED"
       fail "Code smells :${reset} ${qualityGateStatus_code_smells_actualValue}"
   elif [[ ${qualityGateStatus_code_smells} == "WARN" ]]; then
       set_output "quality-gate-code-smells-status" "WARN"
       warn "Code smells :${reset} ${qualityGateStatus_code_smells_actualValue}"
   elif [[ ${qualityGateStatus_code_smells} == "OK" ]]; then
       set_output "quality-gate-code-smells-status" "OK"
       success "Code smells :${reset} ${qualityGateStatus_code_smells_actualValue}"
   fi
   #########################################################################################

   if [[ ${qualityGateStatus_bugs} == "ERROR" ]]; then
       set_output "quality-gate-code-smells-status" "FAILED"
       fail "Bugs :${reset} ${qualityGateStatus_bugs_actualValue}"
   elif [[ ${qualityGateStatus_bugs} == "WARN" ]]; then
       set_output "quality-gate-code-smells-status" "WARN"
       warn "Bugs :${reset} ${qualityGateStatus_bugs_actualValue}"
   elif [[ ${qualityGateStatus_bugs} == "OK" ]]; then
       set_output "quality-gate-code-smells-status" "OK"
       success "Bugs :${reset} ${qualityGateStatus_bugs_actualValue}"
   fi
   #########################################################################################

   title "New Code：${reset}"
   if [[ ${qualityGateStatus_new_code_smells} == "ERROR" ]]; then
       set_output "quality-gate-code-smells-status" "FAILED"
       fail "New code smells :${reset} ${qualityGateStatus_new_code_smells_actualValue}"
   elif [[ ${qualityGateStatus_new_code_smells} == "WARN" ]]; then
       set_output "quality-gate-code-smells-status" "WARN"
       warn "New code smells :${reset} ${qualityGateStatus_new_code_smells_actualValue}"
   elif [[ ${qualityGateStatus_new_code_smells} == "OK" ]]; then
       set_output "quality-gate-code-smells-status" "OK"
       success "New code smells :${reset} ${qualityGateStatus_new_code_smells_actualValue}"
   fi
   if [[ ${qualityGateStatus_new_bugs} == "ERROR" ]]; then
       set_output "quality-gate-code-smells-status" "FAILED"
       fail "New bugs :${reset} ${qualityGateStatus_new_bugs_actualValue}"
   elif [[ ${qualityGateStatus_new_bugs} == "WARN" ]]; then
       set_output "quality-gate-code-smells-status" "WARN"
       warn "New bugs :${reset} ${qualityGateStatus_new_bugs_actualValue}"
   elif [[ ${qualityGateStatus_new_bugs} == "OK" ]]; then
       set_output "quality-gate-code-smells-status" "OK"
       success "New bugs :${reset} ${qualityGateStatus_new_bugs_actualValue}"
   fi

   endoferror "\nhttps://f575-211-23-35-187.ngrok-free.app/api/qualitygates/project_status?analysisId=${analysisId}"
else
   set_output "quality-gate-status" "FAILED"
   fail "Quality Gate not set for the project. Please configure the Quality Gate in SonarQube or remove sonarqube-quality-gate action from the workflow."
   endoferror ""
fi

