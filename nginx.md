# Link to NGINX+ Swagger Def
https://demo.nginx.com/swagger-ui/


# SELinux settings - NGINX Plus Module AppProtect
Issues have been observed with selinux preventing NGINX-Controller agent from making changes to the local file system
```bash
# Execute the following commands as a privilleged user
sudo -s

# Install selinux tools
yum install setools-console -y

# Create nginx.te file that will be used for configuring selinux
cat << EOF > ./nginx-plus-module-appprotect.te
module nginx-plus-module-appprotect 1.0;

require {
        type faillog_t;
        type httpd_t;
        type httpd_log_t;
        type lastlog_t;
        type initrc_t;
        type usr_t;
        type security_t;
        type shadow_t;
        type systemd_logind_t;
        type systemd_logind_sessions_t;
        type unreserved_port_t;
        type var_log_t;
        type var_run_t;
        
        class capability { audit_write net_admin };
        class dbus send_msg;
        class dir { add_name create remove_name write }; 
        class fifo_file write;
        class file { create getattr read rename open setattr unlink write};
        class netlink_selinux_socket { create bind };
        class netlink_audit_socket { create nlmsg_relay read write };
        class passwd passwd;
        class security compute_av;
        class sock_file write;
        class tcp_socket name_connect;
        class unix_stream_socket connectto;
}

#============= httpd_t ==============
allow httpd_t httpd_log_t:file write;

allow httpd_t lastlog_t:file { open read write };

allow httpd_t faillog_t:file { write read open };

allow httpd_t initrc_t:unix_stream_socket connectto;

allow httpd_t unreserved_port_t:tcp_socket name_connect;

allow httpd_t usr_t:dir { add_name create remove_name write };
allow httpd_t usr_t:file { create rename setattr unlink write };
allow httpd_t usr_t:sock_file write;


allow httpd_t security_t:security compute_av;

allow httpd_t self:netlink_selinux_socket {create bind };
allow httpd_t self:netlink_audit_socket { create nlmsg_relay read write };
allow httpd_t self:passwd passwd;
allow httpd_t self:capability { audit_write net_admin };

allow httpd_t shadow_t:file { read write open getattr };

allow httpd_t systemd_logind_sessions_t:fifo_file write;
allow httpd_t systemd_logind_t:dbus send_msg;

allow httpd_t var_log_t:file { open read write };
allow httpd_t var_run_t:file { read write };

#============= systemd_logind_t ==============
allow systemd_logind_t httpd_t:dbus send_msg;
EOF

# Convert text to module
checkmodule -M -m -o ./nginx-plus-module-appprotect.mod ./nginx-plus-module-appprotect.te

# Compile se module
semodule_package -o ./nginx-plus-module-appprotect.pp -m ./nginx-plus-module-appprotect.mod

# Import selinux policy
semodule -i ./nginx-plus-module-appprotect.pp

# Exit Sudo
exit
```

# SELinux settings - NGINX Plus Module f5-metrics
```bash
# Execute the following commands as a privilleged user
sudo -s

# Install selinux tools
yum install setools-console -y

# Create nginx.te file that will be used for configuring selinux
cat << EOF > ./nginx-plus-module-f5-metrics.te
module nginx-plus-module-f5-metrics 1.0;

require {
        type httpd_t;
        type httpd_config_t;
        type tmp_t;

        class file append;
        class sock_file write;
}

#============= httpd_t ==============
allow httpd_t httpd_config_t:file append;
allow httpd_t tmp_t:sock_file write;
EOF

# Convert te file into module
checkmodule -M -m -o ./nginx-plus-module-f5-metrics.mod ./nginx-plus-module-f5-metrics.te

# Compile se module
semodule_package -o ./nginx-plus-module-f5-metrics.pp -m ./nginx-plus-module-f5-metrics.mod

# Import selinux policy
semodule -i ./nginx-plus-module-f5-metrics.pp

exit
```