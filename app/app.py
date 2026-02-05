import os
import requests
from flask import Flask

app = Flask(__name__)

@app.route('/')
def home():
    # --- NEW: IMDSv2 TOKEN LOGIC ---
    try:
        # Step 1: Get the Token
        token_url = "http://169.254.169.254/latest/api/token"
        headers = {"X-aws-ec2-metadata-token-ttl-seconds": "21600"}
        token = requests.put(token_url, headers=headers, timeout=2).text

        # Step 2: Use Token to get Public IP
        meta_headers = {"X-aws-ec2-metadata-token": token}
        public_ip = requests.get("http://169.254.169.254/latest/meta-data/public-ipv4", headers=meta_headers, timeout=2).text
    except Exception:
        public_ip = "Metadata Service Unavailable (Check IMDSv2 settings)"

    # Environment variables injected via Docker run in user_data.sh
    ssh_key_path = os.getenv("SSH_KEY_PATH", "Unknown")
    security_group_id = os.getenv("SECURITY_GROUP_ID", "Unknown")
    instance_type = os.getenv("INSTANCE_TYPE", "Unknown")
    region = os.getenv("REGION", "Unknown")
    vpc_id = os.getenv("VPC_ID", "Unknown")

    return f"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>AWS EC2 Dashboard</title>
        <style>
            * {{ margin: 0; padding: 0; box-sizing: border-box; }}
            body {{
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                min-height: 100vh;
                display: flex;
                justify-content: center;
                align-items: center;
                padding: 20px;
            }}
            .container {{
                background: white;
                border-radius: 20px;
                box-shadow: 0 20px 60px rgba(0,0,0,0.3);
                padding: 40px;
                max-width: 700px;
                width: 100%;
            }}
            .header {{ text-align: center; margin-bottom: 30px; }}
            .header h1 {{ color: #333; font-size: 28px; margin-bottom: 10px; }}
            .status {{
                display: inline-block;
                background: #10b981;
                color: white;
                padding: 8px 20px;
                border-radius: 25px;
                font-size: 14px;
                font-weight: 600;
            }}
            .info-grid {{ display: grid; gap: 20px; margin-top: 30px; }}
            .info-item {{
                background: #f8fafc;
                padding: 20px;
                border-radius: 12px;
                border-left: 4px solid #667eea;
                transition: transform 0.2s, box-shadow 0.2s;
            }}
            .info-item:hover {{
                transform: translateX(5px);
                box-shadow: 0 4px 12px rgba(0,0,0,0.1);
            }}
            .info-label {{
                color: #64748b;
                font-size: 12px;
                font-weight: 600;
                text-transform: uppercase;
                letter-spacing: 0.5px;
                margin-bottom: 8px;
            }}
            .info-value {{
                color: #1e293b;
                font-size: 16px;
                font-weight: 500;
                word-break: break-all;
            }}
            .footer {{
                text-align: center;
                margin-top: 30px;
                padding-top: 20px;
                border-top: 2px solid #e2e8f0;
                color: #64748b;
                font-size: 14px;
            }}
            .aws-logo {{ font-size: 40px; margin-bottom: 10px; }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <div class="aws-logo">☁️</div>
                <h1>AWS EC2 Dashboard</h1>
                <span class="status">✅ Running in Docker</span>
            </div>
            
            <div class="info-grid">
                <div class="info-item">
                    <div class="info-label">Public IP Address</div>
                    <div class="info-value">{public_ip}</div>
                </div>
                <div class="info-item">
                    <div class="info-label">SSH Key Location</div>
                    <div class="info-value">{ssh_key_path}</div>
                </div>
                <div class="info-item">
                    <div class="info-label">Security Group ID</div>
                    <div class="info-value">{security_group_id}</div>
                </div>
                <div class="info-item">
                    <div class="info-label">Instance Type</div>
                    <div class="info-value">{instance_type}</div>
                </div>
                <div class="info-item">
                    <div class="info-label">AWS Region</div>
                    <div class="info-value">{region}</div>
                </div>
                <div class="info-item">
                    <div class="info-label">VPC ID</div>
                    <div class="info-value">{vpc_id}</div>
                </div>
            </div>
            
            <div class="footer">
                🚀 Flask App Continuous Deployment via Jenkins
            </div>
        </div>
    </body>
    </html>
    """

if __name__ == "__main__":
    # Host 0.0.0.0 is mandatory for Docker access
    app.run(host="0.0.0.0", port=5001)