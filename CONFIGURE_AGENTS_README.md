# MongoDB Ops Manager Backup and Monitoring Agent Configuration

## Overview

This playbook configures backup and monitoring agents for MongoDB via MongoDB Ops Manager (MMS) API calls, following MongoDB recommendations. It:

- Sets up monitoring agent configuration
- Sets up backup agent configuration
- Configures log destinations to `/data/mongodb/logs`
- Configures binary destinations to `/opt/mongodb/product`
- Sets up log rotation policies
- Configures alerting rules for critical events

## Prerequisites

- MongoDB Ops Manager instance with API access
- Valid Ops Manager API credentials (username/key and API secret)
- Group ID from your MongoDB Ops Manager organization
- SSH access to target MongoDB hosts
- `ansible` >= 2.9 with `ansible.builtin` collection

## Required Variables

Define these variables in your inventory or group_vars:

```yaml
# MongoDB Ops Manager API Configuration
ops_manager_url: "https://your-ops-manager-instance.com"  # Base URL of your Ops Manager
ops_manager_api_key: "your-api-username"                   # API public key
ops_manager_api_secret: "your-api-secret-key"              # API private key
group_id: "your-group-id"                                  # Organization group ID

# Optional: Notification Configuration
ops_manager_notification_email: "your-email@example.com"   # Email for alert notifications

# Optional: Agent Versions (if not specified, latest compatible versions will be used)
monitoring_agent_version: "11.0.0"
backup_agent_version: "11.0.0"
```

## Directory Structure

The playbook sets up the following directory structure:

```
/data/mongodb/
├── logs/
│   ├── monitoring-agent.log
│   └── backup-agent.log

/opt/mongodb/product/
├── monitoring/
└── backup/
```

## Usage

### Basic Usage

```bash
# Run against all hosts in inventory
ansible-playbook configure_backup_monitoring_agents.yaml

# Run against specific hosts
ansible-playbook configure_backup_monitoring_agents.yaml -i inventory/inventory.ini --limit mongodb_servers

# With extra variables
ansible-playbook configure_backup_monitoring_agents.yaml \
  -e ops_manager_url="https://ops-manager.example.com" \
  -e group_id="507f1f77bcf86cd799439011"
```

### Integration with Inventory

Add to your `inventory/group_vars/all.yaml`:

```yaml
ops_manager_url: "https://ops-manager-stage-db.test.example.com:8443"
ops_manager_api_key: "admin"
ops_manager_api_secret: "your-secret-key"
group_id: "507f1f77bcf86cd799439011"
ops_manager_notification_email: "mongodb-ops@example.com"
```

## What the Playbook Does

### 1. Pre-tasks
- Validates required variables are set
- Creates necessary directories with proper ownership

### 2. Main Tasks
- **Fetch Current Configuration**: Retrieves existing automation config from Ops Manager
- **Configure Monitoring Agent**: Sets up monitoring agent with:
  - Log path: `/data/mongodb/logs/monitoring-agent.log`
  - Binaries path: `/opt/mongodb/product/monitoring`
  
- **Configure Backup Agent**: Sets up backup agent with:
  - Log path: `/data/mongodb/logs/backup-agent.log`
  - Binaries path: `/opt/mongodb/product/backup`

- **Log Rotation**: Configures logrotate for MongoDB logs
- **Apply Configuration**: Waits for automation configuration to be applied
- **Alert Rules**: Sets up monitoring alerts for:
  - Host down events
  - Replication oplog window running out
  - Backup failures
  - Incomplete backups

### 3. Post-tasks
- Verifies all required agent directories exist
- Sets appropriate permissions on log directory
- Displays configuration summary

## API Endpoints Used

- `GET /api/public/v1.0/groups/{GROUP_ID}/automationConfig` - Fetch current configuration
- `PUT /api/public/v1.0/groups/{GROUP_ID}/automationConfig` - Update configuration
- `GET /api/public/v1.0/groups/{GROUP_ID}/automationStatus` - Check deployment status
- `POST /api/public/v1.0/groups/{GROUP_ID}/alertConfigs` - Create alert configurations

## Error Handling

The playbook includes error handling for:
- Missing or invalid API credentials
- Failed API calls (with retry logic)
- Configuration application timeouts
- Missing required variables

Failed tasks are logged and the playbook attempts to continue where possible.

## MongoDB Best Practices Implemented

1. **Separate Agent Logs**: Backup and monitoring agents have separate log files
2. **Dedicated Binary Directory**: Agents run from `/opt/mongodb/product` to avoid conflicts
3. **Proper Permissions**: MongoDB user owns all agents and logs with 0755/0644 permissions
4. **Log Rotation**: Daily rotation with 14-day retention
5. **Alerting**: Critical alerts for backup and replication failures
6. **API Retry Logic**: Automatic retries with delays for transient failures

## Troubleshooting

### "Missing required variables" error
Ensure all required variables are defined in your inventory or passed via `-e` flags.

### "API authentication failed"
Verify your API key and secret are correct in Ops Manager. Check that the user has necessary permissions.

### "Configuration not applying"
Check the Ops Manager UI for any configuration validation errors. Ensure the group_id is correct.

### "Directory permission denied"
Ensure the playbook runs with `become: yes` to create directories with proper ownership.

## Output Example

```
======================================
MongoDB Ops Manager Agent Configuration
========================================
Ops Manager URL: https://ops-manager.example.com
Group ID: 507f1f77bcf86cd799439011
Log Directory: /data/mongodb/logs
Binary Directory: /opt/mongodb/product
Monitoring Agent Config: {'name': 'mmsMonitoring', ...}
Backup Agent Config: {'name': 'mmsBackup', ...}
========================================
```

## Related Files

- `inventory/inventory.ini` - Ansible inventory configuration
- `inventory/group_vars/all.yaml` - Group variables (include Ops Manager settings here)
- `templates/mongodb-logrotate.j2` - Logrotate template for log rotation
- `deploy_mms_agent_service.yaml` - Related playbook for MMS Automation Agent deployment

## References

- [MongoDB Ops Manager API Documentation](https://docs.opsmanager.mongodb.com/current/application/get-started-with-api/)
- [MongoDB Ops Manager Automation Configuration](https://docs.opsmanager.mongodb.com/current/application/deployment/automationConfig/)
- [MongoDB Production Recommendations](https://docs.mongodb.com/manual/administration/production-notes/)
