#!/bin/bash
#set

if [ -n "$INPUT_YAML" ]; then
	encoded=$(cat "$1" | base64 -w0)
fi

if [ ${#INPUT_YAML_URLS[@]} -gt 0 ]; then
  echo "[debug] got INPUT_YAML_URLS"
  for u in ${INPUT_YAML_URLS}
  do
    echo $u
  done
fi


cat << EOF > "${2-event.json}"
{"data":"$encoded", "cluster_name": "${CLUSTER_NAME}", "input_yaml_urls": "${INPUT_YAML_URLS}"} 
EOF


