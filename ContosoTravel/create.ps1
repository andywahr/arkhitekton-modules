[DateTime]::Now.ToString()
& az group delete --name rg-contosotravel-test1 --yes
& az group create --name rg-contosotravel-test1 --location "South Central US"
& 'C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AzCopy.exe'  /Source:. /DestKey:YlzmJVrMArzi5FLV7nH7mCGaG0JDs0Lh1y/Ezmz7bLVMP2UrJ0NvSaGz5QYGDp3ahy41nWdARvUsDjvutPeaYw== /Dest:https://andywahrstorapps.blob.core.windows.net/contosotravel /S /XO /Y
& az group deployment create --name TestDeploy --resource-group rg-contosotravel-test1 --template-file .\azuredeploy.json --parameters namePrefix=andytst1
[DateTime]::Now.ToString()