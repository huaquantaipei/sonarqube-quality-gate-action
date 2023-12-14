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
qualityGateStatus_code_smells="$(curl --location --location-trusted --max-redirs 10 --silent --fail --show-error --user "${SONAR_TOKEN}": "${qualityGateUrl}" | jq -r '.projectStatus.conditions[2].status')"
qualityGateStatus_code_smells_actualValue="$(curl --location --location-trusted --max-redirs 10 --silent --fail --show-error --user "${SONAR_TOKEN}": "${qualityGateUrl}" | jq -r '.projectStatus.conditions[2].actualValue')"
qualityGateStatus_bugs="$(curl --location --location-trusted --max-redirs 10 --silent --fail --show-error --user "${SONAR_TOKEN}": "${qualityGateUrl}" | jq -r '.projectStatus.conditions[3].status')"
qualityGateStatus_bugs_actualValue="$(curl --location --location-trusted --max-redirs 10 --silent --fail --show-error --user "${SONAR_TOKEN}": "${qualityGateUrl}" | jq -r '.projectStatus.conditions[3].actualValue')"



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
   if [[ ${qualityGateStatus_code_smells} == "ERROR" ]]; then
       set_output "quality-gate-code-smells-status" "FAILED"
       fail "code smells :${reset} ${qualityGateStatus_code_smells_actualValue}"
   elif [[ ${qualityGateStatus_code_smells} == "WARN" ]]; then
       set_output "quality-gate-code-smells-status" "WARN"
       warn "code smells :${reset} ${qualityGateStatus_code_smells_actualValue}"
   elif [[ ${qualityGateStatus_code_smells} == "OK" ]]; then
       set_output "quality-gate-code-smells-status" "OK"
       success "code smells :${reset} ${qualityGateStatus_code_smells_actualValue}"
   fi

   if [[ ${qualityGateStatus_bugs} == "ERROR" ]]; then
       set_output "quality-gate-code-smells-status" "FAILED"
       fail "code smells :${reset} ${qualityGateStatus_bugs_actualValue}"
   elif [[ ${qualityGateStatus_bugs} == "WARN" ]]; then
       set_output "quality-gate-code-smells-status" "WARN"
       warn "code smells :${reset} ${qualityGateStatus_bugs_actualValue}"
   elif [[ ${qualityGateStatus_bugs} == "OK" ]]; then
       set_output "quality-gate-code-smells-status" "OK"
       success "bugs :${reset} ${qualityGateStatus_bugs_actualValue}"
   fi

   endoferror "https://f575-211-23-35-187.ngrok-free.app/api/qualitygates/project_status?analysisId=${analysisId}"
else
   set_output "quality-gate-status" "FAILED"
   fail "Quality Gate not set for the project. Please configure the Quality Gate in SonarQube or remove sonarqube-quality-gate action from the workflow."
   endoferror ""
fi

