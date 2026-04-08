# /lambda/update_cloudfront_origin/index.py

import boto3
import os
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    task_arn    = event["detail"]["taskArn"]
    cluster_arn = event["detail"]["clusterArn"]

    ecs = boto3.client("ecs")
    ec2 = boto3.client("ec2")

    # ① ECSタスクの詳細を取得
    tasks = ecs.describe_tasks(cluster=cluster_arn, tasks=[task_arn])["tasks"]
    if not tasks:
        logger.error("Task not found: %s", task_arn)
        return
    task = tasks[0]

    # ② このタスクが属するサービス名を取得（group フィールド: "service:<name>"）
    group = task.get("group", "")
    if not group.startswith("service:"):
        logger.info("Task %s is not service-managed (group=%s), skipping", task_arn, group)
        return
    service_name = group[len("service:"):]

    # ③ サービスで現在 RUNNING 中のタスク一覧を取得し、
    #    このタスクが最新の実行タスクかを確認する（レースコンディション対策）
    running_arns = ecs.list_tasks(
        cluster=cluster_arn,
        serviceName=service_name,
        desiredStatus="RUNNING"
    )["taskArns"]

    if task_arn not in running_arns:
        logger.info(
            "Task %s is no longer running in service %s (current tasks: %s), skipping Route53 update",
            task_arn, service_name, running_arns
        )
        return

    # ④ ENI IDを取得
    eni_id = None
    for attachment in task.get("attachments", []):
        if attachment["type"] == "ElasticNetworkInterface":
            for detail in attachment["details"]:
                if detail["name"] == "networkInterfaceId":
                    eni_id = detail["value"]
                    break
    if not eni_id:
        logger.error("No ENI found for task: %s", task_arn)
        return

    # ⑤ パブリックIPを取得
    eni_info    = ec2.describe_network_interfaces(NetworkInterfaceIds=[eni_id])
    association = eni_info["NetworkInterfaces"][0].get("Association", {})
    public_ip   = association.get("PublicIp")

    if not public_ip:
        logger.error("No public IP assigned to task ENI: %s", eni_id)
        return

    logger.info("New ECS Task public IP: %s", public_ip)

    # ⑥ クロスアカウントロールを引き受けて Route53 クライアントを作成
    #    （Route53ホストゾーンが別アカウント dev-infra-01 にあるため）
    route53_role_arn = os.environ["ROUTE53_ROLE_ARN"]
    sts = boto3.client("sts")
    assumed = sts.assume_role(
        RoleArn=route53_role_arn,
        RoleSessionName="update-ecs-origin"
    )
    creds = assumed["Credentials"]
    route53 = boto3.client(
        "route53",
        aws_access_key_id=creds["AccessKeyId"],
        aws_secret_access_key=creds["SecretAccessKey"],
        aws_session_token=creds["SessionToken"]
    )

    # ⑦ Route53 AレコードをECSタスクのIPに更新
    zone_id         = os.environ["ROUTE53_ZONE_ID"]
    origin_hostname = os.environ["ORIGIN_HOSTNAME"]

    response = route53.change_resource_record_sets(
        HostedZoneId=zone_id,
        ChangeBatch={
            "Comment": "Update ECS task IP",
            "Changes": [{
                "Action": "UPSERT",
                "ResourceRecordSet": {
                    "Name": origin_hostname,
                    "Type": "A",
                    "TTL": 60,
                    "ResourceRecords": [{"Value": public_ip}]
                }
            }]
        }
    )

    logger.info("Route53 record %s updated to %s (ChangeId: %s)",
                origin_hostname, public_ip, response["ChangeInfo"]["Id"])
