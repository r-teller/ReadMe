
```bash
## Clear audit log file
truncate -s 0 /var/log/audit/audit.log

## Start service having an issue
systemctl start nginx

## Search audit events for why
cat /var/log/audit/audit.log | audit2why

## Sometimes events are flagged for noaudit, this command disables noaudit
semodule -DB

## Output audit events to text and merge until all events are allowed
cat /var/log/audit/audit.log | audit2allow -m nginx > nginx.te

# Convert text to module
checkmodule -M -m -o ./nginx.mod ./nginx-plus-module-appprotect.te

# Compile se module
semodule_package -o ./nginx.pp -m ./nginx.mod

# Import selinux policy
semodule -i ./nginx.pp

## Repeat until service works
```