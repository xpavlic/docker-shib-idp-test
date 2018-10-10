#!/bin/sh
docker-compose up --build -d

echo ""
echo "If everything above was successful, your IdP metadata can be retreived with this command (after a minute or two):"
echo "                    curl -k https://127.0.0.1/idp/shibboleth"
echo ""
echo "By default, this test IdP is pre-integrated with the samltest.id testing service."
echo ""
echo "If you are testing the default test config and have port 443 open,"
echo " map your IP to idp.example.edu in your hosts file,"
echo " then proceed to https://samltest.id/start-idp-test to test this IdP test instance."
echo ""

