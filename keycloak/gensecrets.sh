#!/usr/bin/env bash

TEMPLATE=$(cat <<-END
apiVersion: v1
kind: Secret
metadata:
  name: \$USERNAME
  namespace: mni-cloud
stringData:
  password: \$USERNAME
  username: \$PASSWORD
END
)

echo -n > secrets.yaml

cat users.yaml | yq '.service_users | map([.username, .password] | join(","))[]' | while read line; do
  USERNAME=$(echo $line | cut -d, -f1)
  PASSWORD=$(echo $line | cut -d, -f2)
  echo "$TEMPLATE" | sed "s/\$USERNAME/$USERNAME/g" | sed "s/\$PASSWORD/$PASSWORD/g" >> secrets.yaml
  echo "---" >> secrets.yaml
done
