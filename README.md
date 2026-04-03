# Sentinel – Identity Governance & External Cloud Automation

A robust **Salesforce Zero-Trust Identity Governance** solution that automates daily user lifecycle management, proactive access expiry notifications, secure permission set backups, and immutable audit archiving to Google Drive.

This application runs a daily batch process to identify users with expiring access, automates deactivation, sends personalized emails, and provides a manager self-service portal on **Experience Cloud** for bulk security operations. All features are built with strong focus on security, compliance, and maintainability.

![Sentinel - Identity Governance & External Cloud Automation](https://capsule-render.vercel.app/api?type=soft&color=1E3A8A,3B82F6&height=280&section=header&text=Sentinel%20-%20Identity%20Governance&desc=Zero-Trust%20Automation%20%7C%20Daily%20Batch%20%7C%20Google%20Drive%20Archiving&fontSize=36&fontAlignY=48&descAlignY=68&fontColor=ffffff)

**Deployed on Experience Cloud** for easy demonstration to recruiters and guest users.

## ✨ Key Features

- **Daily Automated Lifecycle Management** – Picks users with access end date = today or today + 15 days
- **Smart Deactivation Engine** – Auto-deactivates expired users, creates audit logs, and sends customized emails
- **Proactive Notifications** – Advance warning emails for users expiring in next 15 days
- **Manager Self-Service Portal** – Built on Experience Cloud with multi-select bulk actions
- **Bulk Security Operations** – Password Reset, Reset MFA, Deactivate, and Backup & Purge
- **Intelligent Backup & Purge** – Removes assigned Permission Sets and archives them as CSV to Google Drive for future re-onboarding
- **Real-time Archive Explorer** – LWC component to browse and refresh backed-up CSV files from Google Drive
- **Manual Batch Execution** – Interface to trigger the batch job on-demand
- **Conditional UI Logic** – Action buttons enabled only when valid users are selected

## 🚀 Business Impact

- Automated daily security hygiene process
- Significantly reduced manual effort for IT and managers
- Strengthened **Zero-Trust** security by timely revocation of access
- Enabled faster user re-onboarding using backed-up Permission Sets
- Eliminated risk of stale accounts and unnecessary license consumption

## ▶️ Watch Demo
> **YouTube**: I will update soon ......

## 🛠️ Tech Stack

- **Apex** • **Batch Apex** • **Queueable Apex** • **Triggers**
- **LWC** • **Custom Metadata Types**
- **Email Templates** • **Experience Cloud (LWR)**
- **Named Credentials** • **OAuth 2.0** • **Google Drive API**
- **CSV Generation** • **Security & Integration**

## 📋 Project Highlights

### Automated Identity Governance
- Daily Batch Apex identifies users expiring **today** and in the **next 15 days**
- Automatically deactivates users whose access ends today
- Creates detailed audit records in a custom object
- Sends personalized deactivation and reminder emails using custom Email Templates

### Manager Self-Service Interface (Experience Cloud)
- Multi-select datatable for managers to choose users
- Bulk actions: **Password Reset**, **Reset MFA**, **Deactivate**, and **Backup & Purge**
- Conditional button enabling – “Reset MFA”, “Password Reset”, and “Deactivate” buttons are enabled only when at least one **active** user is selected
- **Backup & Purge** functionality removes assigned Permission Sets and generates a CSV containing User Full Name, Email, Permission Set Name, and Label

### Secure Google Drive Archiving
- CSV backup files are uploaded to a dedicated Google Drive folder via Named Credentials
- Real-time LWC File Explorer in the **Archive** tab with a **Refresh** button to fetch latest files
- Folder ID and integration settings managed through Custom Metadata for easy configuration

### Technical Challenges Overcome
- Handled **Mixed DML Exception** (Setup vs Non-Setup objects) by using **Queueable Apex** to separate transactions
- Implemented secure external integration best practices with Named Credentials and OAuth 2.0
- Ensured governor limit safety in Batch and Queueable processing

### Smart License Handling
- License removal is not explicitly coded — Salesforce automatically releases licenses when a user is deactivated

## 📁 Project Structure

```bash
Sentinel-Identity-Governance/
├── force-app/
│   ├── main/
│   │   ├── default/
│   │   │   ├── classes/               # Batch Class, Queueable, Service Layer, Controller, CSV Generator
│   │   │   ├── triggers/              # Audit logging and user triggers
│   │   │   ├── lwc/                   # Manager Portal, Bulk Actions & Google Drive Explorer
│   │   │   ├── customMetadata/        # Configuration (Drive Folder ID, Named Credentials)
│   │   │   ├── email/                 # Custom Email Templates
│   │   │   ├── experiences/           # Experience Cloud (LWR) Site
│   │   │   └── security/              # Permission Sets & Profiles
│   └── ...
├── screenshots/
└── README.md
```
## 📸 Screenshots

Manager Portal Dashboard with Multi-Select
<img src="screenshots/dashboard.png" alt="Manager Dashboard">
Bulk Actions Interface (Password Reset, Reset MFA, Deactivate, Backup & Purge)
<img src="screenshots/bulk-actions.png" alt="Bulk Actions">
Real-time LWC Google Drive Archive Explorer with Refresh Button
<img src="screenshots/file-explorer.png" alt="Archive Vault">
Daily Batch Execution Logs & Audit Records
<img src="screenshots/batch-logs.png" alt="Batch & Audit Logs">
Custom Email Templates (Deactivation & Reminder)
<img src="screenshots/email-templates.png" alt="Email Templates">
Custom Metadata Configuration Screen
<img src="screenshots/custom-metadata.png" alt="Configuration">

📱✨ Mobile View

Manager Portal & Bulk Actions (Mobile)
<img src="screenshots/mobile1.png" alt="Mobile View 1">
Archive Explorer & Refresh (Mobile)
<img src="screenshots/mobile2.png" alt="Mobile View 2">


<div align="center">

<div style="background: linear-gradient(145deg, #0d1117 0%, #161b22 100%); border: 1px solid #30363d; border-radius: 20px; padding: 40px; max-width: 1100px; margin: 24px auto; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; color: #e6edf3; box-shadow: 0 20px 40px rgba(0,0,0,0.3);">

<!-- 🏗️ Architecture Highlights -->
<div style="margin-bottom: 36px;">
  <h3 style="display: flex; align-items: center; gap: 12px; font-size: 24px; font-weight: 700; color: #58a6ff; margin: 0 0 28px 0; padding-bottom: 16px; border-bottom: 2px solid #30363d; text-shadow: 0 2px 4px rgba(88,166,255,0.2);">🏗️ Architecture Highlights</h3>
  
  <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 20px;">
    
    <!-- Card 1: Daily Batch -->
    <div style="background: linear-gradient(145deg, #161b22, #1a1e24); border: 1px solid #21262d; border-radius: 16px; padding: 24px; transition: all 0.3s ease; position: relative; overflow: hidden;">
      <div style="position: absolute; top: 0; left: 0; width: 100%; height: 4px; background: linear-gradient(90deg, #10b981, #34d399);"></div>
      <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 16px;">
        <div style="width: 48px; height: 48px; background: rgba(16,185,129,0.1); border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 20px; border: 1px solid rgba(16,185,129,0.3);">⚙️</div>
        <div>
          <div style="font-size: 16px; font-weight: 700; color: #e6edf3;">Daily Batch & Queueable</div>
          <div style="font-size: 12px; color: #8b949e;">Governor-safe automation</div>
        </div>
      </div>
      <ul style="font-size: 13px; color: #b1bac4; line-height: 1.6; margin: 0; padding-left: 20px;">
        <li>Processes today and next 15 days expiries</li>
        <li>Automated deactivation + audit logging</li>
        <li><strong>Queueable Apex</strong> to handle Mixed DML</li>
      </ul>
    </div>

    <!-- Card 2: Zero-Trust Security -->
    <div style="background: linear-gradient(145deg, #161b22, #1a1e24); border: 1px solid #21262d; border-radius: 16px; padding: 24px; transition: all 0.3s ease; position: relative; overflow: hidden;">
      <div style="position: absolute; top: 0; left: 0; width: 100%; height: 4px; background: linear-gradient(90deg, #ef4444, #f87171);"></div>
      <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 16px;">
        <div style="width: 48px; height: 48px; background: rgba(239,68,68,0.1); border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 20px; border: 1px solid rgba(239,68,68,0.3);">🔐</div>
        <div>
          <div style="font-size: 16px; font-weight: 700; color: #e6edf3;">Zero-Trust Security</div>
          <div style="font-size: 12px; color: #8b949e;">Compliance ready</div>
        </div>
      </div>
      <ul style="font-size: 13px; color: #b1bac4; line-height: 1.6; margin: 0; padding-left: 20px;">
        <li>Timely access revocation</li>
        <li>Secure Named Credentials + <strong>OAuth 2.0</strong></li>
        <li>Full audit trail for compliance</li>
      </ul>
    </div>

    <!-- Card 3: Manager Self-Service -->
    <div style="background: linear-gradient(145deg, #161b22, #1a1e24); border: 1px solid #21262d; border-radius: 16px; padding: 24px; transition: all 0.3s ease; position: relative; overflow: hidden;">
      <div style="position: absolute; top: 0; left: 0; width: 100%; height: 4px; background: linear-gradient(90deg, #f59e0b, #fbbf24);"></div>
      <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 16px;">
        <div style="width: 48px; height: 48px; background: rgba(245,158,11,0.1); border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 20px; border: 1px solid rgba(245,158,11,0.3);">👥</div>
        <div>
          <div style="font-size: 16px; font-weight: 700; color: #e6edf3;">Manager Self-Service</div>
          <div style="font-size: 12px; color: #8b949e;">Bulk operations portal</div>
        </div>
      </div>
      <ul style="font-size: 13px; color: #b1bac4; line-height: 1.6; margin: 0; padding-left: 20px;">
        <li>Multi-select with conditional UI logic</li>
        <li>Backup & Purge with CSV generation</li>
        <li>Permission Set removal + archiving</li>
      </ul>
    </div>

    <!-- Card 4: Secure Archiving -->
    <div style="background: linear-gradient(145deg, #161b22, #1a1e24); border: 1px solid #21262d; border-radius: 16px; padding: 24px; transition: all 0.3s ease; position: relative; overflow: hidden;">
      <div style="position: absolute; top: 0; left: 0; width: 100%; height: 4px; background: linear-gradient(90deg, #8b5cf6, #a78bfa);"></div>
      <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 16px;">
        <div style="width: 48px; height: 48px; background: rgba(139,92,246,0.1); border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 20px; border: 1px solid rgba(139,92,246,0.3);">☁️</div>
        <div>
          <div style="font-size: 16px; font-weight: 700; color: #e6edf3;">Secure Archiving</div>
          <div style="font-size: 12px; color: #8b949e;">Google Drive integration</div>
        </div>
      </div>
      <ul style="font-size: 13px; color: #b1bac4; line-height: 1.6; margin: 0; padding-left: 20px;">
        <li>Real-time LWC Google Drive explorer</li>
        <li>Refresh functionality from Drive folder</li>
        <li>Metadata-driven configuration</li>
      </ul>
    </div>

  </div>
</div>

<!-- 🎯 Architect Skills -->
<div style="margin-bottom: 36px;">
  <h3 style="display: flex; align-items: center; gap: 12px; font-size: 24px; font-weight: 700; color: #58a6ff; margin: 0 0 28px 0; padding-bottom: 16px; border-bottom: 2px solid #30363d; text-shadow: 0 2px 4px rgba(88,166,255,0.2);">🎯 Architect Skills Demonstrated</h3>
  
  <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px;">
    
    <div style="display: flex; gap: 20px;">
      <div style="width: 4px; height: 100%; background: linear-gradient(180deg, #10b981, #34d399); border-radius: 2px;"></div>
      <div style="flex: 1; background: linear-gradient(145deg, #161b22, #1a1e24); border: 1px solid #21262d; border-radius: 16px; padding: 24px;">
        <div style="font-size: 16px; font-weight: 700; color: #10b981; margin-bottom: 12px;">Batch Apex & Queueable</div>
        <div style="font-size: 13px; color: #b1bac4; line-height: 1.6;">Complex scheduled processing & <strong>Mixed DML handling</strong></div>
      </div>
    </div>

    <div style="display: flex; gap: 20px;">
      <div style="width: 4px; height: 100%; background: linear-gradient(180deg, #ef4444, #f87171); border-radius: 2px;"></div>
      <div style="flex: 1; background: linear-gradient(145deg, #161b22, #1a1e24); border: 1px solid #21262d; border-radius: 16px; padding: 24px;">
        <div style="font-size: 16px; font-weight: 700; color: #ef4444; margin-bottom: 12px;">Identity Governance & Zero-Trust</div>
        <div style="font-size: 13px; color: #b1bac4; line-height: 1.6;">End-to-end automated user lifecycle</div>
      </div>
    </div>

    <div style="display: flex; gap: 20px;">
      <div style="width: 4px; height: 100%; background: linear-gradient(180deg, #f59e0b, #fbbf24); border-radius: 2px;"></div>
      <div style="flex: 1; background: linear-gradient(145deg, #161b22, #1a1e24); border: 1px solid #21262d; border-radius: 16px; padding: 24px;">
        <div style="font-size: 16px; font-weight: 700; color: #f59e0b; margin-bottom: 12px;">Secure External Integration</div>
        <div style="font-size: 13px; color: #b1bac4; line-height: 1.6;"><strong>OAuth 2.0</strong> + Named Credentials with Google Drive</div>
      </div>
    </div>

    <div style="display: flex; gap: 20px;">
      <div style="width: 4px; height: 100%; background: linear-gradient(180deg, #8b5cf6, #a78bfa); border-radius: 2px;"></div>
      <div style="flex: 1; background: linear-gradient(145deg, #161b22, #1a1e24); border: 1px solid #21262d; border-radius: 16px; padding: 24px;">
        <div style="font-size: 16px; font-weight: 700; color: #8b5cf6; margin-bottom: 12px;">Experience Cloud (LWR)</div>
        <div style="font-size: 13px; color: #b1bac4; line-height: 1.6;">Manager self-service portal for guest/demo users</div>
      </div>
    </div>

  </div>
</div>

<!-- 🔮 Planned Enhancements -->
<div style="margin-bottom: 40px;">
  <h3 style="display: flex; align-items: center; gap: 12px; font-size: 24px; font-weight: 700; color: #58a6ff; margin: 0 0 28px 0; padding-bottom: 16px; border-bottom: 2px solid #30363d; text-shadow: 0 2px 4px rgba(88,166,255,0.2);">🔮 Planned Enhancements</h3>
  
  <div style="display: flex; flex-wrap: wrap; gap: 16px; font-size: 14px;">
    <span style="background: rgba(16,185,129,0.1); border: 1px solid rgba(16,185,129,0.3); color: #10b981; padding: 12px 20px; border-radius: 25px; font-weight: 600; white-space: nowrap;">Real-time Slack/Email alerts</span>
    <span style="background: rgba(245,158,11,0.1); border: 1px solid rgba(245,158,11,0.3); color: #f59e0b; padding: 12px 20px; border-radius: 25px; font-weight: 600; white-space: nowrap;">One-click Restore functionality</span>
    <span style="background: rgba(139,92,246,0.1); border: 1px solid rgba(139,92,246,0.3); color: #8b5cf6; padding: 12px 20px; border-radius: 25px; font-weight: 600; white-space: nowrap;">Compliance reporting dashboard</span>
    <span style="background: rgba(239,68,68,0.1); border: 1px solid rgba(239,68,68,0.3); color: #ef4444; padding: 12px 20px; border-radius: 25px; font-weight: 600; white-space: nowrap;">Multi-cloud storage support</span>
  </div>
</div>

<!-- 🚀 Deployment Steps -->
<div style="margin-bottom: 40px;">
  <h3 style="display: flex; align-items: center; gap: 12px; font-size: 24px; font-weight: 700; color: #58a6ff; margin: 0 0 28px 0; padding-bottom: 16px; border-bottom: 2px solid #30363d; text-shadow: 0 2px 4px rgba(88,166,255,0.2);">🚀 Deployment Steps</h3>
  
  <div style="background: linear-gradient(145deg, #0d1117, #0f1419); border: 1px solid #30363d; border-radius: 16px; overflow: hidden; font-family: 'SF Mono', Monaco, 'Cascadia Code', monospace;">
    <div style="background: #161b22; padding: 16px 24px; border-bottom: 1px solid #30363d; display: flex; align-items: center; justify-content: space-between; font-size: 14px; font-weight: 600;">
      <span style="color: #58a6ff;">$</span> <span style="color: #e6edf3;">Deploy Sentinel</span>
      <span style="background: rgba(88,166,255,0.1); color: #58a6ff; padding: 4px 12px; border-radius: 6px; font-size: 12px;">bash</span>
    </div>
    <div style="padding: 24px; background: #0a0e12; font-size: 14px; line-height: 1.7; color: #8b949e;">
      <div style="color: #58a6ff; margin-bottom: 8px;">git clone https://github.com/Venkat152/Sentinel-Identity-Governance.git</div>
      <div style="color: #58a6ff; margin-bottom: 8px;">cd Sentinel-Identity-Governance</div>
      <div style="color: #58a6ff; margin-bottom: 8px;">sf org login web --alias sentinel</div>
      <div style="color: #58a6ff; margin-bottom: 16px;">sf project deploy start</div>
      <div style="color: #10b981; font-weight: 700; font-size: 15px;">Site live! 🎉 Experience Cloud ready</div>
    </div>
    <div style="padding: 16px 24px; background: #0d1117; border-top: 1px solid #30363d; font-size: 13px; color: #8b949e; display: flex; align-items: center; gap: 8px;">
      <span>📦</span> Prerequisites: Salesforce CLI + Experience Cloud License
    </div>
  </div>
</div>

<!-- 👨‍💻 Author -->
<div style="padding-top: 32px; border-top: 2px solid #30363d; text-align: center;">
  <div style="font-size: 16px; color: #8b949e; margin-bottom: 12px;">
    Architected with ❤️ by <strong style="color: #e6edf3; font-size: 18px;">Venkatesh M</strong>
  </div>
  <div style="font-size: 14px; color: #8b949e;">
    <strong>Salesforce Developer/Architect</strong> • Capgemini India
  </div>
</div>

</div>

<style>
div:hover {
  transform: translateY(-4px);
  box-shadow: 0 24px 48px rgba(0,0,0,0.4);
}
</style>

</div>