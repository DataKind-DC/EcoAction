# https://stackoverflow.com/questions/60139095/how-to-upload-and-deploy-zip-file-to-aws-elastic-beanstalk-via-cli
envir="prod"
appname="arlington-trees-api"
awsprofile="brentmagnusson3"

aws elasticbeanstalk describe-environments --application-name $appname --profile $awsprofile > aws/describe-environments.json
v=$(cat aws/describe-environments.json | jq -r '.Environments[] | select(.EnvironmentName | contains("arlington-trees-api-dev")) | .VersionLabel')
echo "Deplying version "$v" To "$envir
aws elasticbeanstalk update-environment --application-name $appname --environment-name $appname-$envir --version-label $v --profile $awsprofile > aws/update-environment.json




