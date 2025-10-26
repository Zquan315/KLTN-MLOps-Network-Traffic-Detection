import os
import boto3
import datetime
import json

ses_client = boto3.client('ses')
SENDER_EMAIL = os.environ['SENDER_EMAIL']
TO_EMAIL = os.environ['TO_EMAIL']

def lambda_handler(event, context):
    
    # 'event' chứa một batch các tin nhắn từ SQS
    # Đếm số lượng tấn công trong batch này
    attack_count = len(event.get('Records', []))
    
    if attack_count == 0:
        return {'statusCode': 200, 'body': 'No records'}
        
    print(f"Received batch of {attack_count} attack alerts.")

    # Tạo nội dung email
    now = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')
    subject = f"[IDS Alert] {attack_count} Attacks Redirected to Honeypot"
    body = f"""
    IDS Alert Notification:
    
    On: {now}
    Amount of traffics (ATTACK) detected and redirected to Honeypot system: {attack_count}
    
    Please check the IDS dashboard for more details.
    This is an automated message. Please do not reply.
    """
    
    # Gửi email qua SES
    try:
        ses_client.send_email(
            Source=SENDER_EMAIL,
            Destination={'ToAddresses': [TO_EMAIL]},
            Message={
                'Subject': {'Data': subject},
                'Body': {'Text': {'Data': body}}
            }
        )
        print(f"Successfully sent email alert for {attack_count} attacks.")
        
    except Exception as e:
        print(f"Error sending email: {e}")
        # Ném lỗi để SQS có thể thử lại
        raise e

    return {'statusCode': 200, 'body': json.dumps('Alert email sent!')}