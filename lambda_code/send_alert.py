import json
import boto3
from datetime import datetime, timezone, timedelta 

ses = boto3.client('ses', region_name='us-east-1')

def lambda_handler(event, context):
    
    if isinstance(event.get('body'), str):
        body = json.loads(event['body'])
    else:
        body = event.get('body', {})
    
    subject = body.get('subject', 'IDS Alert')
    html_body = body.get('body', '')
    count = body.get('count', 0)
    timestamp = body.get('timestamp', datetime.now().isoformat())
    
    if 'Z' in timestamp or '+00:00' in timestamp:
        # Timestamp là UTC
        dt_utc = datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
        dt_vn = dt_utc.astimezone(timezone(timedelta(hours=7)))
    elif '+07:00' in timestamp:
        # Timestamp đã là UTC+7
        dt_vn = datetime.fromisoformat(timestamp)
    else:
        # No timezone info → assume UTC+7
        dt_naive = datetime.fromisoformat(timestamp)
        dt_vn = dt_naive.replace(tzinfo=timezone(timedelta(hours=7)))
        
    date_str = dt_vn.strftime('%Y%m%d')
    download_link = f"http://honeypot.qmuit.id.vn/logs/{date_str}"
        
    download_section = f"""
        <hr style="margin: 20px 0; border: none; border-top: 1px solid #ddd;">
        <div style="background: #f8f9fa; padding: 15px; border-radius: 5px; margin-top: 20px;">
            <h3 style="color: #28a745; margin: 0 0 10px 0;">📥 Download Attack Logs</h3>
            <p style="margin: 5px 0;">
                <strong>Date:</strong> {date_str}<br>
                <strong>Total Records:</strong> {count} flows
            </p>
            <a href="{download_link}" 
               style="display: inline-block; 
                      margin-top: 10px; 
                      padding: 10px 20px; 
                      background: #007bff; 
                      color: white; 
                      text-decoration: none; 
                      border-radius: 5px;
                      font-weight: bold;">
                🔗 Download CSV Log File
            </a>
            <p style="margin-top: 10px; font-size: 12px; color: #666;">
                Click the button above or copy this link:<br>
                <code style="background: #e9ecef; padding: 2px 5px; border-radius: 3px;">{download_link}</code>
            </p>
        </div>
        """
    if '</body>' in html_body:
        html_body = html_body.replace('</body>', f'{download_section}</body>')
    else:
        html_body += download_section
    
    # Send email via SES
    try:
        response = ses.send_email(
            Source='tocongquan315@gmail.com',  # Verified email
            Destination={
                'ToAddresses': ['tocongquan315@gmail.com']  # Your email
            },
            Message={
                'Subject': {'Data': subject, 'Charset': 'UTF-8'},
                'Body': {'Html': {'Data': html_body, 'Charset': 'UTF-8'}}
            }
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Email sent successfully',
                'messageId': response['MessageId'],
                'download_link': download_link
            })
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }