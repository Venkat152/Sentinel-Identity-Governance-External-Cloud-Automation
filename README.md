# Sentinel – Identity Governance & External Cloud Automation

A powerful **Salesforce Zero-Trust Identity Governance** solution that automates user lifecycle management, proactive expiry notifications, and secure audit archiving to Google Drive.

This application runs daily to identify users with upcoming or immediate access expiry, automates deactivation, sends personalized notifications, and enables managers to perform bulk security actions through an intuitive Experience Site interface.

![Sentinel - Identity Governance & External Cloud Automation](https://capsule-render.vercel.app/api?type=soft&color=1E3A8A,3B82F6&height=280&section=header&text=Sentinel%20-%20Identity%20Governance&desc=Zero-Trust%20Automation%20%7C%20Daily%20Batch%20%7C%20Google%20Drive%20Archiving&fontSize=36&fontAlignY=48&descAlignY=68&fontColor=ffffff)

Built with a strong focus on security, automation, compliance, and user experience on **Salesforce Experience Cloud**.

## ✨ Key Features

- **Daily Automated User Lifecycle Management** – Identifies users expiring today and in next 15 days
- **Smart Deactivation Logic** – Automatically deactivates expired users + creates audit logs
- **Proactive Email Notifications** – Customized emails sent to users and managers for upcoming expiries
- **Manager Self-Service Portal** – Intuitive Experience Site interface for bulk security operations
- **Bulk Security Actions** – Password Reset, Reset MFA, Deactivate, and Backup & Purge
- **Automated Audit Archiving** – Secure backup of user permissions to Google Drive as CSV files
- **Real-time LWC File Explorer** – View archived CSV files directly in Salesforce without leaving the platform

## 🚀 Business Impact

- Automated daily security hygiene process
- Reduced manual IT and manager overhead significantly
- Strengthened **Zero-Trust** security posture by timely deactivation of access
- Enabled faster user re-onboarding through permission set backup & restore
- Eliminated risk of stale user accounts lingering in the system

## ▶️ Watch Demo
> **YouTube**: I will update soon ......

## 🛠️ Tech Stack

- **Apex** • **Batch Apex** • **Triggers**
- **LWC** • **Custom Metadata Types**
- **Email Templates** • **Experience Cloud (LWR)**
- **Named Credentials** • **OAuth 2.0** • **Google Drive API**
- **Security** • **Integration** • **CSV Generation**

## 📋 Project Highlights

### Automated Identity Governance
- Daily Batch Apex job picks users whose access end date is **today** or **today + 15 days**
- Automatically deactivates users expiring today
- Creates detailed audit logs in a custom object
- Sends personalized deactivation emails to affected users

### Proactive Expiry Management
- Sends advance warning emails to users whose access will expire in the next 15 days
- Helps managers take proactive action before access is revoked

### Manager Self-Service Interface
- Built on **Experience Cloud** for managers
- Multi-select capability to choose multiple users
- Bulk actions: **Password Reset**, **Reset MFA**, **Deactivate**, and **Backup & Purge**
- "Backup & Purge" generates CSV with User Full Name, Email, Permission Set Name & Label for future re-onboarding

### Secure Archive Vault
- CSV files are automatically uploaded to a dedicated Google Drive folder using Named Credentials
- Real-time LWC component to browse and refresh archived files directly inside Salesforce
- Folder ID and integration settings managed via Custom Metadata for easy configuration

### Smart License Management
- License removal not handled in batch — Salesforce automatically releases licenses upon user deactivation

## 📁 Project Structure

```bash
Sentinel-Identity-Governance/
├── force-app/
│   ├── main/
│   │   ├── default/
│   │   │   ├── classes/               # Batch Class, Service Layer, Controller, CSV Generator
│   │   │   ├── triggers/              # User & Audit logging triggers
│   │   │   ├── lwc/                   # Manager Portal + Google Drive File Explorer
│   │   │   ├── customMetadata/        # Configuration (Folder ID, Named Credentials)
│   │   │   ├── email/                 # Custom Email Templates
│   │   │   ├── experiences/           # Experience Cloud Site configuration
│   │   │   └── security/              # Permission Sets & Profiles
│   └── ...
├── screenshots/
└── README.md

📸 Screenshots

Manager Portal Dashboard
<img src="screenshots/dashboard.png" alt="Manager Dashboard">
Multi-Select User Interface with Bulk Actions
<img src="screenshots/bulk-actions.png" alt="Bulk Actions">
Real-time LWC Google Drive Archive Explorer
<img src="screenshots/file-explorer.png" alt="Archive Vault">
Daily Batch Execution & Audit Logs
<img src="screenshots/batch-logs.png" alt="Batch & Audit Logs">
Email Templates (Deactivation & Reminder)
<img src="screenshots/email-templates.png" alt="Email Templates">
Custom Metadata Configuration
<img src="screenshots/custom-metadata.png" alt="Configuration">

📱✨ Mobile View

Manager Portal & Bulk Actions (Mobile)
<img src="screenshots/mobile1.png" alt="Mobile View 1">
Archive Explorer & Refresh (Mobile)
<img src="screenshots/mobile2.png" alt="Mobile View 2">

🏗️ Architecture Highlights

      ⚙️ Daily Batch Automation
      
        Processes today's and upcoming expiries
        Automated deactivation + audit logging
        Personalized email notifications
      
    
      🔐 Zero-Trust Security
      
        Timely access revocation
        Secure Named Credentials integration
        Audit trail for compliance
      
    
      👥 Manager Self-Service
      
        Multi-select bulk operations
        Conditional button enabling logic
        Permission Set Backup as CSV
      
    
      ☁️ Secure Google Drive Archiving
      
        Real-time LWC file explorer
        Refresh functionality from Drive folder
        Metadata-driven configuration
      
    
🎯 Architect Skills Demonstrated

      
        Batch Apex & Automation
Complex daily scheduled processing
        Identity Governance & Zero-Trust
End-to-end user lifecycle automation
      
    
      
        Secure External Integration
OAuth 2.0 + Named Credentials with Google Drive
        Experience Cloud Development
Manager self-service portal on LWR
      
    
🔮 Planned Enhancements

Real-time Slack notifications for critical actions
Automated compliance reporting dashboard
One-click Restore from Backup CSV
Support for additional cloud storage providers

🚀 Deployment Steps

Clone the repository
Authenticate to your Salesforce org
Deploy the source using Salesforce CLI
Configure Named Credentials and Custom Metadata
Set up the Experience Cloud site
Schedule the Daily Batch Apex job

Bashgit clone https://github.com/Venkat152/Sentinel-Identity-Governance.git
cd Sentinel-Identity-Governance
sf org login web --alias sentinel
sf project deploy start
👨‍💻 Author
Venkatesh M
Salesforce Developer | Capgemini | India