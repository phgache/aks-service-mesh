#!/bin/bash

#
# Integrate Azure Active Directory
#

echo "Cleanup ad"

appId=$(az ad app list --all --query '[].{AppId:appId}' --display-name $1 -o tsv)

for id in $spId
do
    echo "delete sp $id"
    az ad sp delete --id $id
done

spId=$(az ad sp list --all --query '[].{AppId:appId}' --display-name $1 -o tsv)

for id in $appId
do
    echo "delete app $id"
    az ad app delete --id $id
done

# /// Create Azure AD service principal ///

echo "Create the Azure AD service principal"
SERVICE_PRINCIPAL_PASSWORD=$(az ad sp create-for-rbac \
    --role Contributor \
    --name "${1}ServicePrincipal" \
    --query password --output tsv)
SERVICE_PRINCIPAL_ID=$(az ad sp show \
    --id "http://${1}ServicePrincipal" \
    --query appId --output tsv)
echo " ==> $SERVICE_PRINCIPAL_ID created"

# /// Create Azure AD server component ///

if [ "$2" = "true" ]
then
    echo "Create the server application ..."
    SERVER_APPLICATION_ID=$(az ad app create \
        --display-name "${1}Server" \
        --identifier-uris "https://${1}Server" \
        --query appId -o tsv)
    echo " ==> $SERVER_APPLICATION_ID created"

    echo "Update the application group memebership claims"
    az ad app update --id $SERVER_APPLICATION_ID --set groupMembershipClaims=All

    echo "Create a service principal for the server application"
    SP_SERVER_APPLICATION_ID=$(az ad sp create --id $SERVER_APPLICATION_ID --query objectId -o tsv)
    echo " ==> $SP_SERVER_APPLICATION_ID created"

    # Get the service principal secret
    echo "Get the service principal secret"
    SERVER_APPLICATION_SECRET=$(az ad sp credential reset \
        --name ${SERVER_APPLICATION_ID} \
        --credential-description "AKS_Password" \
        --query password -o tsv)

    # /// Grant permissions ///

    az ad app permission add \
        --id $SERVER_APPLICATION_ID \
        --api 00000003-0000-0000-c000-000000000000 \
        --api-permissions e1fe6dd8-ba31-4d61-89e7-88639da4683d=Scope 06da0dbc-49e2-44d2-8312-53f166ab848a=Scope 7ab1d382-f21e-4acd-a863-ba3e13f7da61=Role

    az ad app permission grant --id $SERVER_APPLICATION_ID --api 00000003-0000-0000-c000-000000000000
    oAuthPermissionId=$(az ad app show --id $SERVER_APPLICATION_ID --query "oauth2Permissions[0].id" -o tsv)
    az ad app permission add --id $CLIENT_APPLICATION_ID --api $SERVER_APPLICATION_ID --api-permissions $oAuthPermissionId=Scope
    az ad app permission grant --id $CLIENT_APPLICATION_ID --api $SERVER_APPLICATION_ID

    while [ "$(az ad app permission list-grants --id $SERVER_APPLICATION_ID --query "[].{Scope:scope}" -o tsv)" = "user_impersonation" ]
    do 
        echo "Grant admin consent"
        az ad app permission admin-consent --id $SERVER_APPLICATION_ID
        sleep 10
    done
else
    echo "AAD integration disabled"
fi

echo "*********************** AAD Application ***********************"
az ad app list --all --query '[].{Id:objectId, Type:objectType, AppId:appId, Name:displayName}' -o table --display-name "${1}Server"
az ad app list --all --query '[].{Id:objectId, Type:objectType, AppId:appId, Name:displayName}' -o table --display-name "${1}Client"
if [ "$2" = "true" ]
then
    echo "*********************** AAD Service Principal ***********************"
    az ad sp list --all --query '[].{Id:objectId, Type:objectType, AppId:appId, Name:displayName}' -o table --display-name "${1}Server"
    az ad sp list --all --query '[].{Id:objectId, Type:objectType, AppId:appId, Name:displayName}' -o table --display-name "${1}Client"
    az ad sp list --all --query '[].{Id:objectId, Type:objectType, AppId:appId, Name:displayName}' -o table --display-name "${1}ServicePrincipal"

    echo "*** AAD SERVER_APPLICATION_ID $SERVER_APPLICATION_ID roles ***"
    az ad app permission list --query '[].resourceAccess[].{Id:id, Type:type}' --id $SERVER_APPLICATION_ID -o table
    echo "*** AAD CLIENT_APPLICATION_ID $CLIENT_APPLICATION_ID roles ***"
    az ad app permission list --query '[].resourceAccess[].{Id:id, Type:type}' --id $CLIENT_APPLICATION_ID -o table
    echo "*** AAD SERVER_APPLICATION_ID $SERVER_APPLICATION_ID grants ***"
    az ad app permission list-grants --id $SERVER_APPLICATION_ID --query "[].{Id:clientId,Type:consentType,Scope:scope}" -o table
fi
TENANT_ID=$(az account show --query tenantId -o tsv)

echo "*********************** Exports ***********************"
echo "TENANT_ID=$TENANT_ID"
export TENANT_ID=$TENANT_ID
echo "SERVICE_PRINCIPAL_ID=$SERVICE_PRINCIPAL_ID"
export SERVICE_PRINCIPAL_ID=$SERVICE_PRINCIPAL_ID
echo "SERVICE_PRINCIPAL_PASSWORD=$SERVICE_PRINCIPAL_PASSWORD"
export SERVICE_PRINCIPAL_PASSWORD=$SERVICE_PRINCIPAL_PASSWORD

if [ "$2" = "true" ]
then
    echo "SERVER_APPLICATION_ID=$SERVER_APPLICATION_ID"
    export SERVER_APPLICATION_ID=$SERVER_APPLICATION_ID
    echo "SERVER_APPLICATION_SECRET=$SERVER_APPLICATION_SECRET"
    export SERVER_APPLICATION_SECRET=$SERVER_APPLICATION_SECRET
    echo "CLIENT_APPLICATION_ID=$CLIENT_APPLICATION_ID"
    export CLIENT_APPLICATION_ID=$CLIENT_APPLICATION_ID
fi

echo "*******************************************************"


