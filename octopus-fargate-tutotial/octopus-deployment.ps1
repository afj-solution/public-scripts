#Libarary Variables 
$ServiceLogGroup = $OctopusParameters["AWS.ECS.CloudWatch.Group"]
$Region = $OctopusParameters["AWS.Region.name"]
$Subnet = $OctopusParameters["AWS.Subnet.Id"]
$SecurityGroup = $OctopusParameters["AWS.Microservice.SecurityGroup.Id"] 
$ClusterName = $OctopusParameters["AWS.ECS.Cluster.Name"]

# Project variables
$TaskName = $OctopusParameters["Project.AWS.ECS.TaskDefinition.Name"]
$ServiceName = $OctopusParameters["Project.AWS.ECS.Service.Name"]
$ServiceLogPrefix = $OctopusParameters["Project.AWS.ECS.CloudWatch.Prefix"]
$TaskDefinitionCpu = $OctopusParameters["Project.AWS.ECS.TaskDefinition.Cpu"]
$TaskDefinitionMemory = $OctopusParameters["Project.AWS.ECS.TaskDefinition.Memory"]
$ContainerName = $OctopusParameters["Project.AWS.ECS.TaskDefinition.Container.Name"]
$AutoAssignIp = $OctopusParameters["Project.AWS.ECS.AutoAssignIp"]
$TargetGroupArn = $OctopusParameters["Project.AWS.ECS.TargetGroupArn"]

# Env variables of the container
$EnvVariables = $OctopusParameters["Project.AWS.ECS.TaskDefinition.Container.Env"]

#Get execution role ARN
$ExecutionRole = $(Get-IAMRole -RoleName "ecsTaskExecutionRole").Arn

# Add container settings settings
$webPortMappings = New-Object "System.Collections.Generic.List[Amazon.ECS.Model.PortMapping]"
$webPortMappings.Add($(New-Object -TypeName "Amazon.ECS.Model.PortMapping" -Property @{ HostPort=80; ContainerPort=80; Protocol=[Amazon.ECS.TransportProtocol]::Tcp}))

#Add environment variable to the container
$webEnvironmentVariables = New-Object "System.Collections.Generic.List[Amazon.ECS.Model.KeyValuePair]"
$webEnvironmentVariables.Add($(New-Object -TypeName "Amazon.ECS.Model.KeyValuePair" -Property @{ Name="VERSION"; Value=$OctopusParameters["Octopus.Action.Package[buy-it-api].PackageVersion"]}))

if (-not [String]::IsNullOrEmpty($EnvVariables)) {
   foreach ($param in (ConvertFrom-Csv -Delimiter '=' -Header Name,Value -InputObject $EnvVariables)) {
        $name = $param.Name
        $value = $param.Value
    	Write-Host "Add $name = $value to the container env variable"
        $webEnvironmentVariables.Add($(New-Object -TypeName "Amazon.ECS.Model.KeyValuePair" -Property @{ Name=$name; Value=$value}))
    }
}

# Add Cloud Wacth options
$logOption=New-Object "System.Collections.Generic.Dictionary[System.String,System.String]"
$logOption.Add("awslogs-group", $ServiceLogGroup)
$logOption.Add("awslogs-region", $Region)
$logOption.Add("awslogs-stream-prefix", $ServiceLogPrefix)

$logDefinitions = New-Object "Amazon.ECS.Model.LogConfiguration"
$logDefinitions.LogDriver = [Amazon.ECS.LogDriver]::Awslogs
$logDefinitions.Options = $logOption

# Add container definitions 
$ContainerDefinitions = New-Object "System.Collections.Generic.List[Amazon.ECS.Model.ContainerDefinition]"
$ContainerDefinitions.Add($(New-Object -TypeName "Amazon.ECS.Model.ContainerDefinition" -Property @{ `
Name=$ContainerName; `
Image=$OctopusParameters["Octopus.Action.Package[buy-it-api].Image"]; `
PortMappings=$webPortMappings; `
Environment=$webEnvironmentVariables; `
LogConfiguration=$logDefinitions;}))

# Create a Load balancer 
$LoadBalancers = New-Object "System.Collections.Generic.List[Amazon.ECS.Model.LoadBalancer]"
$LoadBalancers.Add($(New-Object -TypeName "Amazon.ECS.Model.LoadBalancer" -Property @{ `
ContainerName=$ContainerName; `
ContainerPort=80; `
TargetGroupArn=$TargetGroupArn;}))

Write-Host "Created a Load Balancer $LoadBalancerName and $TargetGroupArn"

$TaskDefinition = Register-ECSTaskDefinition `
-ContainerDefinition $ContainerDefinitions `
-Cpu $TaskDefinitionCpu `
-Family $TaskName `
-TaskRoleArn $ExecutionRole `
-ExecutionRoleArn $ExecutionRole `
-Memory $TaskDefinitionMemory `
-NetworkMode awsvpc `
-Region $Region `
-RequiresCompatibility "FARGATE"

if(!$?)
{
    Write-Error "Failed to register new task definition"
    Exit 0
}

# Check to see if there is a service already
$service = (Get-ECSService -Cluster $ClusterName -Service $ServiceName)

$launchType = $(New-Object -TypeName "Amazon.ECS.Launchtype" -ArgumentList "FARGATE")
$assignPublicIp = $(New-Object -TypeName "Amazon.ECS.AssignPublicIp" -ArgumentList $AutoAssignIp)

if ($service.Services.Count -eq 0)
{
    Write-Host "Service $ServiceName doesn't exist, creating ..."
    $ServiceCreate = New-ECSService `
        -Cluster $ClusterName `
        -ServiceName $ServiceName `
        -TaskDefinition $TaskDefinition.TaskDefinitionArn `
        -LoadBalancer $LoadBalancers `
        -DesiredCount 1 `
        -AwsvpcConfiguration_AssignPublicIp $assignPublicIp `
        -AwsvpcConfiguration_Subnet @($Subnet) `
        -AwsvpcConfiguration_SecurityGroup @($SecurityGroup) `
        -LaunchType $launchType
}
else
{
    Write-Host "Service $ServiceName  exist ..."
    # Get Running task ARN to stop if after create new one
    $RunningTaskArn = (Get-ECSTaskList -Cluster  $ClusterName -ServiceName $ServiceName)
    
    $ServiceUpdate = Update-ECSService `
        -Cluster $ClusterName `
        -ForceNewDeployment $true `
        -Service $ServiceName `
        -TaskDefinition $TaskDefinition.TaskDefinitionArn `
        -AwsvpcConfiguration_AssignPublicIp $assignPublicIp `
        -AwsvpcConfiguration_Subnet @($Subnet) `
        -AwsvpcConfiguration_SecurityGroup @($SecurityGroup)
        
    Start-Sleep -Seconds 10
    #Stop old task 
    Write-Host "Stop old task $RunningTaskArn  ..."
    Stop-ECSTask -Cluster $ClusterName -Task $RunningTaskArn
}

if(!$?)
{
    Write-Error "Failed to register new task definition"
    Exit 0
}

# Save task definition to output variable
Set-OctopusVariable -Name "TaskDefinitionArn" -Value $TaskDefinition.TaskDefinitionArn