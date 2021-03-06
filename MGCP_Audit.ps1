#CAT (Chris' Automation Tool) for MGCP
#
#Script uses powershell GCP SDK
#https://cloud.google.com/sdk/docs/quickstart-windows

#Parameters
$Date = Get-Date -Format yyyyMM
$DestDir =""

#LogFile for troubleshooting/Auditing
$LogFile = "$((Get-Date).ToString("yyyyMMdd_HHmmss"))log.txt"
New-Item $LogFile -ItemType File -ErrorAction Stop
Start-Transcript -path $LogFile -append -noclobber

#Obtain list of GCP projects which have been allowed access
gcloud projects list --format="csv(projectId)" > MGCP_accounts.csv

#Obtain list of CloudSQL instanced

$projects = Import-Csv "./MGCP_accounts.csv"

foreach ($MGCP_Project in $projects.project_id) {
	
	#Set GPC Project
	gcloud config set project $MGCP_Project
	
	#Output list of APIS with status (Enabled/Disabled)
	gcloud services list --available --format="csv(config.title,state)" > $MGCP_Project`_API.csv
	
	#Output compute regions to a temporary file, de-duplicate and create new file to Destination Directory
	gcloud compute instances list --format="csv(zone)" > "./$($MGCP_Project)_ZonesTemp.csv"
	$ZonesTemp = "./$($MGCP_Project)_ZonesTemp.csv"
	$RegionsTemp = Import-Csv $ZonesTemp | Sort-Object zone -Unique
	$RegionsTemp | Export-Csv "$MGCP_Project`_Zones.csv" -NoTypeInformation
	$RegionsCsv = "$(($RegionsTemp[1].zone -split '-')[0])-$(($RegionsTemp[1].zone -split '-')[1])"
	
	#Output Global Quotas to Destination Directory
	gcloud compute project-info describe --flatten="quotas[]" --format="csv(name,quotas.metric,quotas.limit,quotas.usage)" > $MGCP_Project`_GlobalQuotas.csv

	#Output Regional Quotas to Destination Directory
	#Does NOT currently have the ability to query multiple regions within a single project.
	#Look to use gcloud config set compute/zone NAME
	#Look to use gcloud config set compute/region NAME
	gcloud compute regions describe $RegionsCsv --flatten="quotas[]" --format="csv(quotas.metric,quotas.limit,quotas.usage)" > $MGCP_Project`_RegionalQuotas.csv

	#Output Monitoring Policies to Destination Directory
	gcloud alpha monitoring policies list --format="csv(enabled,displayName,documentation.content,mutationRecord.mutateTime,mutationRecord.mutatedBy)" > $MGCP_Project`_MonitoringPolicy.csv

	#Output Firewall Rules to Destination Directory
	gcloud compute firewall-rules list --format="csv(name,network,direction,priority,sourceRanges.list():label=SRC_RANGES,destinationRanges.list():label=DEST_RANGES,allowed[].map().firewall_rule().list():label=ALLOW,denied[].map().firewall_rule().list():label=DENY,sourceTags.list():label=SRC_TAGS,sourceServiceAccounts.list():label=SRC_SVC_ACCT,targetTags.list():label=TARGET_TAGS,targetServiceAccounts.list():label=TARGET_SVC_ACCT,disabled)" > $MGCP_Project`_NetworkFirewallRules.csv

	#Output Snapshots to Destination Directory
	gcloud compute snapshots list --format="csv(name,disk_size_gb,source_disk,creationTimestamp,status)" > $MGCP_Project`_Snapshots.csv

	#Output SSL Certificate Details to Destination Directory
	gcloud compute ssl-certificates list --format="csv(name,type,creation_timestamp,expire_time,subjectAlternativeNames)" > $MGCP_Project`_SSLCertificates.csv

	#Output Disks to Destination Directory
	gcloud compute disks list --format="csv(name,zone,size_gb,type,sourceImage,users,lastAttachTimestamp)" > $MGCP_Project`_Disks.csv

	#Output Committed Usage Discounts to Destination Directory
	gcloud compute commitments list --format="csv(name,region,end_TimeStamp,status)" > $MGCP_Project`_CommittedUsageDiscount.csv
	
	#Output Compute Instances to Destination Directory
	gcloud compute instances list --format="csv(name,status,zone,machine_type,preemptible)" > $MGCP_Project`_ComputeInstances.csv
	
	#Output CloudSQL instaces list for query
	#gcloud sql instances list --format="csv(cloudsqlId)" > $MGCP_Project`_CloudSQLInstances.csv
	#$CloudSQLInstancesTemp = Import-Csv "./$MGCP_Project`_CloudSQLInstances.csv"
	#foreach ($CloudSQLInstancesTemp in $projects.project_id) {
	
}

#Add Filename to last column for filtering
Get-ChildItem *.csv | ForEach-Object {
    $CSV = Import-CSV -Path $_.FullName -Delimiter ","
    $FileName = $_.Name

    $CSV | Select-Object *,@{N='Filename';E={$FileName}} | Export-CSV $_.FullName -NTI -Delimiter ","
}

#Merge all CSV into their own individual product master CSV file
Get-ChildItem -Filter *_API.csv | Select-Object -ExpandProperty FullName | Import-Csv | Export-Csv $Date`_API.csv -NoTypeInformation -Append
Get-ChildItem -Filter *_GlobalQuotas.csv | Select-Object -ExpandProperty FullName | Import-Csv | Export-Csv $Date`_GlobalQuotas.csv -NoTypeInformation -Append
Get-ChildItem -Filter *_RegionalQuotas.csv | Select-Object -ExpandProperty FullName | Import-Csv | Export-Csv $Date`_RegionalQuotas.csv -NoTypeInformation -Append
Get-ChildItem -Filter *_MonitoringPolicy.csv | Select-Object -ExpandProperty FullName | Import-Csv | Export-Csv $Date`_MonitoringPolicy.csv -NoTypeInformation -Append
Get-ChildItem -Filter *_NetworkFirewallRules.csv | Select-Object -ExpandProperty FullName | Import-Csv | Export-Csv $Date`_NetworkFirewallRules.csv -NoTypeInformation -Append
Get-ChildItem -Filter *_Snapshots.csv | Select-Object -ExpandProperty FullName | Import-Csv | Export-Csv $Date`_Snapshots.csv -NoTypeInformation -Append
Get-ChildItem -Filter *_SSLCertificates.csv | Select-Object -ExpandProperty FullName | Import-Csv | Export-Csv $Date`_SSLCertificates.csv -NoTypeInformation -Append
Get-ChildItem -Filter *_Disks.csv | Select-Object -ExpandProperty FullName | Import-Csv | Export-Csv $Date`_Disks.csv -NoTypeInformation -Append
Get-ChildItem -Filter *_CommittedUsageDiscount.csv | Select-Object -ExpandProperty FullName | Import-Csv | Export-Csv $Date`_CommittedUsageDiscount.csv -NoTypeInformation -Append
Get-ChildItem -Filter *_ComputeInstances.csv | Select-Object -ExpandProperty FullName | Import-Csv | Export-Csv $Date`_ComputeInstances.csv -NoTypeInformation -Appendb

#Tidy-up by removing all project CSV files
foreach ($MGCP_Project in $projects.project_id) {
Remove-Item $MGCP_Project`*.csv -Verbose -Force
}

#Tidy up list of GCP projects
#Remove-Item MGCP_accounts.csv -Verbose -Force
