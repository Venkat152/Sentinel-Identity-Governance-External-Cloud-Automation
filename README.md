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

<h2 align="left">🏗️ Architecture Highlights</h2>

<table>
  <tr>
    <td valign="top" width="50%">
      <h3 align="left">⚙️ Daily Batch & Queueable</h3>
      <p align="left"><i>Governor-safe automation</i></p>
      <ul>
        <li>Processes today and next 15 days expiries</li>
        <li>Automated deactivation + audit logging</li>
        <li><b>Queueable Apex</b> to handle Mixed DML</li>
      </ul>
    </td>
    <td valign="top" width="50%">
      <h3 align="left">🔐 Zero-Trust Security</h3>
      <p align="left"><i>Compliance ready</i></p>
      <ul>
        <li>Timely access revocation</li>
        <li>Secure Named Credentials + <b>OAuth 2.0</b></li>
        <li>Full audit trail for compliance</li>
      </ul>
    </td>
  </tr>
  <tr>
    <td valign="top" width="50%">
      <h3 align="left">👥 Manager Self-Service</h3>
      <p align="left"><i>Bulk operations portal</i></p>
      <ul>
        <li>Multi-select with conditional UI logic</li>
        <li>Backup &amp; Purge with CSV generation</li>
        <li>Permission Set removal + archiving</li>
      </ul>
    </td>
    <td valign="top" width="50%">
      <h3 align="left">☁️ Secure Archiving</h3>
      <p align="left"><i>Google Drive integration</i></p>
      <ul>
        <li>Real-time LWC Google Drive explorer</li>
        <li>Refresh functionality from Drive folder</li>
        <li>Metadata-driven configuration</li>
      </ul>
    </td>
  </tr>
</table>

<br>

<h2 align="left">🎯 Architect Skills Demonstrated</h2>

<table>
  <tr>
    <td valign="top" width="50%">
      <h3 align="left">Batch Apex &amp; Queueable</h3>
      <p align="left">Complex scheduled processing &amp; <b>Mixed DML handling</b></p>
    </td>
    <td valign="top" width="50%">
      <h3 align="left">Identity Governance &amp; Zero-Trust</h3>
      <p align="left">End-to-end automated user lifecycle</p>
    </td>
  </tr>
  <tr>
    <td valign="top" width="50%">
      <h3 align="left">Secure External Integration</h3>
      <p align="left"><b>OAuth 2.0</b> + Named Credentials with Google Drive</p>
    </td>
    <td valign="top" width="50%">
      <h3 align="left">Experience Cloud (LWR)</h3>
      <p align="left">Manager self-service portal for guest/demo users</p>
    </td>
  </tr>
</table>

<br>

<h2 align="left">🔮 Planned Enhancements</h2>

<ul>
  <li>Real-time Slack/Email alerts for critical security events</li>
  <li>One-click Restore functionality from backup CSV</li>
  <li>Automated compliance reporting dashboard</li>
  <li>Support for additional cloud storage providers</li>
</ul>

<br>

<h2 align="left">🚀 Deployment Steps</h2>

<ol>
  <li>Clone the repository</li>
  <li>Authenticate to your Salesforce org</li>
  <li>Deploy the source using Salesforce CLI</li>
  <li>Configure Named Credentials and Custom Metadata (Drive Folder ID)</li>
  <li>Set up the Experience Cloud site for demo/guest access</li>
  <li>Schedule the Daily Batch Apex job</li>
</ol>

```bash
git clone https://github.com/Venkat152/Sentinel-Identity-Governance.git
cd Sentinel-Identity-Governance
sf org login web --alias sentinel
sf project deploy start
```

<h2 align="left">👨‍💻 Author</h2>

<p align="left">
  <b>Venkatesh M</b><br>
  Salesforce Developer | Capgemini | India
</p>