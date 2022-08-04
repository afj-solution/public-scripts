#!/bin/bash
NAME=$1
VPC_ID=$2
SUBNET_ID=$3
CERTIFICATE_ID=$4
ROUTE_NAME=$5
HOSTED_ZONE_ID=$6

elastic_file_name="elastic.json"
temp_file_name="temp.json"

echo "Create a taget group ecs-$NAME-target-group. Protocol TCP and port 80"

targetGroupArn=$(aws elbv2 create-target-group \
    --name ecs-$NAME-target-group \
    --protocol TCP \
    --port 80 \
    --target-type ip \
    --vpc-id $VPC_ID | jq -r '.TargetGroups' | jq .[0] | jq .TargetGroupArn | sed "s/\"//g")

sleep 2
echo "Created a target group with ARN: $targetGroupArn"

echo "Create a network load balancer with name ecs-$NAME-elbv to the subnet $SUBNET_ID"

loadBalancerResponse=$(aws elbv2 create-load-balancer --name ecs-$NAME-elbv --type network --subnet-mappings SubnetId=$SUBNET_ID)

echo "$loadBalancerResponse" >> $elastic_file_name

arn=$(jq -r .LoadBalancers[0].LoadBalancerArn $elastic_file_name | sed "s/\"//g")
loadBalancerDns=$(jq -r .LoadBalancers[0].DNSName $elastic_file_name | sed "s/\"//g")

echo "Created a load balancer with ARN: $arn"

echo "Create a TLS linstener to the target group $targetGroupArn with certificate $CERTIFICATE_ID"

result=$(aws elbv2 create-listener --load-balancer-arn $arn --protocol TLS --port 443 --alpn-policy HTTP2Optional --default-actions Type=forward,TargetGroupArn=$targetGroupArn --certificates CertificateArn=$CERTIFICATE_ID)
sleep 2

echo "Create a TCP linstener to the target group $targetGroupArn"

result=$(aws elbv2 create-listener --load-balancer-arn $arn --protocol TCP --port 80 --default-actions Type=forward,TargetGroupArn=$targetGroupArn)

echo "Wait until the Load balancer created"
sleep 10

route_53_json='
{
   "Comment":"Daily update",
   "Changes":[
      {
         "Action":"UPSERT",
         "ResourceRecordSet":{
            "Name":"'$ROUTE_NAME'.afj-solution.com",
            "Type":"A",
            "AliasTarget":{
               "HostedZoneId":"ZLMOA37VPKANP",
               "DNSName":"'$loadBalancerDns'",
               "EvaluateTargetHealth":false
            }
         }
      },
      {
         "Action":"UPSERT",
         "ResourceRecordSet":{
            "Name":"www.'$ROUTE_NAME'.afj-solution.com",
            "Type":"A",
            "AliasTarget":{
               "HostedZoneId":"ZLMOA37VPKANP",
               "DNSName":"'$loadBalancerDns'",
               "EvaluateTargetHealth":false
            }
           
         }
      }
   ]
}'

echo $route_53_json > temp.json

aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch file://temp.json

echo "Clean up"
rm -r $elastic_file_name
rm -r $temp_file_name