#Parameters
$Date = Get-Date -Format yyMMdd
$DestDir ="RAW"

#Obtain list of GCP projects which have been allowed access
gcloud projects list --format="csv(projectId)" > MGCP_accounts.csv

$projects = Import-Csv "./MGCP_accounts.csv"

foreach ($MGCP_Project in $projects.project_id) {
	
	#Set GPC Project
	gcloud config set project $MGCP_Project
	
	#Output compute regions to a tempoary file, de-duplicate and create new file to Destination Directory
	gcloud compute instances list --format="csv(zone)" > "$($MGCP_Project)_ZonesTemp.csv"
	$ZonesTemp = "./$($MGCP_Project)_ZonesTemp.csv"
	$RegionsTemp = Import-Csv $ZonesTemp | Sort-Object zone -Unique
	$RegionsTemp | Export-Csv "$MGCP_Project`_Zones.csv" -NoTypeInformation
	$RegionsCsv = "$(($RegionsTemp[1].zone -split '-')[0])-$(($RegionsTemp[1].zone -split '-')[1])"	

	#Output Global Quotas to Destination Directory
	gcloud compute project-info describe --flatten="quotas[]" --format="csv(name,quotas.metric,quotas.limit,quotas.usage)" > $MGCP_Project`_GlobalQuotas.csv

	#Output Regional Quotas to Destination Directory
	gcloud compute regions describe europe-west2 --flatten="quotas[]" --format="csv(quotas.metric,quotas.limit,quotas.usage)" > $MGCP_Project`_RegionalQuotas.csv

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

	#Output Commited Useage Discounts to Destination Directory
	gcloud compute commitments list --format="csv(name,region,end_TimeStamp,status)" > $MGCP_Project`_CommitedUsageDiscount.csv
	
	#Output Compute Instances to Destination Directory
	gcloud compute instances list --format="csv(name,status,zone,machine_type,preemptible)" > $MGCP_Project`_ComputeInstances.csv
}

#SQL

#List Buckets
