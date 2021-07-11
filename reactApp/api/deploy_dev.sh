# https://stackoverflow.com/questions/60139095/how-to-upload-and-deploy-zip-file-to-aws-elastic-beanstalk-via-cli
envir="dev"
appname="arlington-trees-api"
awsprofile="brentmagnusson3"
echo "Deploying "$appname-$envir
zip ../api_deploy.zip -r * -x ./aws/\*
aws s3 cp ../api_deploy.zip s3://arlington-trees-api/api_deploy.zip --profile $awsprofile

aws elasticbeanstalk describe-environments --application-name $appname --profile $awsprofile > aws/describe-environments.json
v=$(cat aws/describe-environments.json | jq -r '.Environments[] | select(.EnvironmentName | contains("arlington-trees-api-dev")) | .VersionLabel')
echo "Current Version "$v
newv=$((v+1))
echo "New Version "$newv
aws elasticbeanstalk create-application-version --application-name $appname --version-label $newv --source-bundle S3Bucket="arlington-trees-api",S3Key="api_deploy.zip" --profile $awsprofile > aws/create-application-version.json
aws elasticbeanstalk update-environment --application-name $appname --environment-name $appname-$envir --version-label $newv --profile $awsprofile > aws/update-environment.json




