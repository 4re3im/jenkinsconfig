#!/bin/bash -e

account=("backoffice-nonprod")

accountlength="${#account[@]}"
accountlength="$((accountlength-1))"

for (( c=0; c<=$accountlength; c++ ))
do
	for REGION in $(aws ec2 describe-regions --output text --query 'Regions[].[RegionName]') 
	do
		echo "${account[$c]}[$REGION]"
		echo "==================================================="
		snapshot="aws ec2 --region "$REGION" describe-snapshots --owner-ids self --query \"Snapshots[?StartTime<'$(date --date='-1 month' '+%Y-%m-%d')'].SnapshotId\" --output text | tr '\t' '\n' | sort"
		echo $snapshot|bash>>"snapshot_${account[$c]}_$REGION".txt
		if [ -s "snapshot_${account[$c]}_$REGION".txt ]
		then
			echo $snapshot
			snapshotvolume="aws ec2 --region "$REGION" describe-volumes --query 'Volumes[*].SnapshotId' --output text | tr '\t' '\n' | sort | uniq"
			snapshotami="aws ec2 --region "$REGION" describe-images --filters Name=state,Values=available --owners self --query "Images[*].BlockDeviceMappings[*].Ebs.SnapshotId" --output text | tr '\t' '\n' | sort | uniq"
			echo $snapshotvolume|bash>>"ssvolumeami_${account[$c]}_$REGION".txt | echo $snapshotami|bash>>"ssvolumeami_${account[$c]}_$REGION".txt
			if [ -s "ssvolumeami_${account[$c]}_$REGION".txt ]
			then
				echo $snapshotvolume
				echo $snapshotami
				echo "Sorting"
				sort "ssvolumeami_${account[$c]}_$REGION".txt | uniq > "ssvolumeami_${account[$c]}_$REGION-sorted".txt
				echo -e "Determining Orphaned Snapshots"
				comm -23 "snapshot_${account[$c]}_$REGION".txt "ssvolumeami_${account[$c]}_$REGION-sorted".txt>> "ssvolumeami_${account[$c]}_$REGION-orphan".txt
				if [ -s "ssvolumeami_${account[$c]}_$REGION-orphan".txt ]
				then
					
					echo "===================================================">>"${account[$c]}".txt
					echo "${account[$c]}[$REGION]">>"${account[$c]}".txt
					echo "===================================================">>"${account[$c]}".txt
					cat "ssvolumeami_${account[$c]}_$REGION-orphan".txt>>"${account[$c]}".txt
					echo -e "\n">>"${account[$c]}".txt
					rm -rf "ssvolumeami_${account[$c]}_$REGION-orphan".txt "ssvolumeami_${account[$c]}_$REGION-sorted".txt "ssvolumeami_${account[$c]}_$REGION".txt "snapshot_${account[$c]}_$REGION".txt
					echo -e "Successful\n===================================================\n"
				else
					rm -rf "ssvolumeami_${account[$c]}_$REGION-orphan".txt "ssvolumeami_${account[$c]}_$REGION-sorted".txt "ssvolumeami_${account[$c]}_$REGION".txt "snapshot_${account[$c]}_$REGION".txt
					echo -e "No orphaned snapshots\n===================================================\n"
				fi
			else
				echo "No Volume/AMI ID"
				echo "===================================================">>"${account[$c]}".txt
				echo "${account[$c]}[$REGION]">>"${account[$c]}".txt
				echo "===================================================">>"${account[$c]}".txt
				cat "snapshot_${account[$c]}_$REGION".txt>>"${account[$c]}".txt
				echo -e "\n">>"${account[$c]}".txt
				rm -rf "ssvolumeami_${account[$c]}_$REGION".txt "snapshot_${account[$c]}_$REGION".txt
				echo -e "Successful\n===================================================\n"
			fi
		else
			rm -rf "snapshot_${account[$c]}_$REGION".txt
			echo -e "No snapshot\n===================================================\n"
		fi
	done
done
