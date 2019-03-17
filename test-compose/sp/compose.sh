#!/bin/sh
docker-compose up --build -d

if [ $? == '0' ]; then
 echo ""
 echo "If everything above was successful, your SP metadata can be retreived with this command (after a minute or two):"
 echo "                    curl -k -s https://127.0.0.1:8443/Shibboleth.sso/Metadata"
 echo ""
else
 echo "An error was encountered."
fi
