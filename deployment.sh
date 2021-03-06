#!/bin/bash

#nameprefix="notejamapp"
read -p "Enter a unique app prefix, e.g. notejam83 : " nameprefix

resourceGroupName=$nameprefix
location="westeurope"
location2="northeurope"
registryName=$nameprefix"acr"
imageName=$nameprefix
appName=$nameprefix"-app"
backendPoolName=$nameprefix"-backend"
appName1=$appName"-"$location
appName2=$appName"-"$location2
servicePlan1=$nameprefix"-asp-1"
servicePlan2=$nameprefix"-asp-2"
frontdoorName=$nameprefix"-fd"
sqlServer=$nameprefix"-server"
sqlDatabase="notejam"
sqlDatabaseDev=$sqlDatabase"dev"
sqlAdminUser=$nameprefix"admin"
read -s -p "Enter SQL Admin Password with chars, numbers and special characters : " sqlAdminPassword
sqlDatabaseUri="mysql+pymysql://"$sqlAdminUser"@"$sqlServer":"$sqlAdminPassword"@"$sqlServer".mysql.database.azure.com:3306/"$sqlDatabase"?charset=utf8"
sqlDatabaseUriDev="mysql+pymysql://"$sqlAdminUser"@"$sqlServer":"$sqlAdminPassword"@"$sqlServer".mysql.database.azure.com:3306/"$sqlDatabaseDev"?charset=utf8"

echo "Creating Resource Group '$resourceGroupName'"
az group create --name $resourceGroupName --location $location

echo "Creating Container Registry"
az deployment group create --resource-group $resourceGroupName --template-file ./ARM-Templates/azure-container-registry.json --parameters registry_name=$registryName location=$location location2=$location2

echo "Deploy initial Docker Container to ACR"
az acr build -t $imageName:dev -t $imageName:int -t $imageName:prd -r $registryName .

echo "Creating MySQL Server with replica"
az deployment group create --resource-group $resourceGroupName --template-file ./ARM-Templates/mysql.json --parameters serverName=$sqlServer databaseName=$sqlDatabase databaseNameDev=$sqlDatabaseDev adminUserName=$sqlAdminUser adminPassword=$sqlAdminPassword location=$location location2=$location2

echo "Getting Admin credentials from ACR"
credentials=$(az acr credential show -n $registryName)
username=$(echo $credentials | jq -r '.username')
password=$(echo $credentials | jq -r '.passwords[0].value')

echo "Creating Web App in $location"
az deployment group create --resource-group $resourceGroupName --template-file ./ARM-Templates/webapp.json --parameters app_name=$appName1 app_service_plan_name=$servicePlan1 container_registry_uri=$registryName".azurecr.io" container_image_name=$imageName location=$location acr_admin_user=$username acr_admin_password=$password sql_database_uri=$sqlDatabaseUri sql_database_uri_dev=$sqlDatabaseUriDev

echo "Creating Web App in $location2"
az deployment group create --resource-group $resourceGroupName --template-file ./ARM-Templates/webapp.json --parameters app_name=$appName2 app_service_plan_name=$servicePlan2 container_registry_uri=$registryName".azurecr.io" container_image_name=$imageName location=$location2 acr_admin_user=$username acr_admin_password=$password sql_database_uri=$sqlDatabaseUri sql_database_uri_dev=$sqlDatabaseUriDev

echo "Creating Front Door"
az deployment group create --resource-group $resourceGroupName --template-file ./ARM-Templates/frontdoor.json --parameters frontdoor_name=$frontdoorName backend_poolname=$backendPoolName backend_name_1=$appName1 backend_name_2=$appName2 


echo "Execute the following statement to retrieve secrets for GitHub Actions"
echo 'az ad sp create-for-rbac --name "GitHubActions" --role contributor --sdk-auth'
