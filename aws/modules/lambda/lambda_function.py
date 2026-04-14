import boto3
import time
import os

INSTANCE_ID  = os.environ["INSTANCE_ID"]
IMAGE        = os.environ["DOCKER_IMAGE"]
APP_DIR      = os.environ["APP_DIR"]        # e.g. /home/ubuntu/link_monitor
SCRIPT_NAME  = os.environ["SCRIPT_NAME"]    # e.g. screenshot_checker_1.py

ec2 = boto3.client("ec2")
ssm = boto3.client("ssm")

def lambda_handler(event, context):
    print(f"Starting EC2 instance: {INSTANCE_ID}")

    # 1. Start EC2
    ec2.start_instances(InstanceIds=[INSTANCE_ID])
    ec2.get_waiter("instance_running").wait(
        InstanceIds=[INSTANCE_ID],
        WaiterConfig={"Delay": 15, "MaxAttempts": 40}
    )
    print("EC2 is running. Waiting 30s for SSM agent to connect...")
    time.sleep(30)

    # 2. Run Docker container via SSM
    # Volume mount (-v) is required so screenshots/logs written inside the
    # container persist on the EC2 filesystem outside the container.
    # APP_DIR on EC2 is mounted to /app inside the container.
    docker_cmd = (
        f"docker pull {IMAGE} && "
        f"docker run --rm "
        f"-v {APP_DIR}:/app "
        f"{IMAGE} python /app/{SCRIPT_NAME}"
    )
    response = ssm.send_command(
        InstanceIds=[INSTANCE_ID],
        DocumentName="AWS-RunShellScript",
        Parameters={
            "commands": [docker_cmd]
        },
        TimeoutSeconds=600
    )
    command_id = response["Command"]["CommandId"]
    print(f"SSM command dispatched: {command_id}")

    # 3. Poll until command completes (max 5 min)
    for attempt in range(30):
        time.sleep(10)
        result = ssm.get_command_invocation(
            CommandId=command_id,
            InstanceId=INSTANCE_ID
        )
        status = result["Status"]
        print(f"Attempt {attempt+1}: SSM status = {status}")
        if status in ("Success", "Failed", "Cancelled", "TimedOut"):
            print(f"stdout: {result.get('StandardOutputContent', '')}")
            print(f"stderr: {result.get('StandardErrorContent', '')}")
            break

    # 4. Stop EC2
    print("Stopping EC2 instance...")
    ec2.stop_instances(InstanceIds=[INSTANCE_ID])
    print("Done.")
    return {"status": status, "command_id": command_id}
