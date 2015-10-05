#!/usr/bin/env ruby
# Ryan C. Moon 
# 2014-09-15
# Generic securing script for Ubuntu 14.04 LTS versions on VPSs quickly.
# Works for ruby versions > 1.9.1
# This script assumes you have installed ruby via rvm (https://rvm.io/rvm/install) or apt-get install ruby
# This file must be run as root. Assumes this is a default server install, I use this to quickly
# install and secure VPS and VMs with basic "no pants down moments" security.
# * I recommend running `apt-get update; apt-get upgrade` before doing this script or it might take a while..
# ** Setup networking first and put interface names in this file..
#
# Changelog
# 2014-09-15 Initial Development
# 2015-03-13 Added heat/sensors packages for reasons..
# 2015-06-17 Updated syslog-ng install

#### Defaults and CONSTs -- CHANGE THESE
DEBUG = true
ROUTER = false                           # Enable to turn on forwarding and masquerade via iptables
ENABLE_SYSLOG = false                    # Disable if you do not remote syslog this server
DATE = Time.now
DEFAULT_HDD = '/dev/sda'
NETWORKING_INTERFACE_INTERNAL = 'p1p1'
NETWORKING_INTERFACE_EXTERNAL = 'p1p1'  # if you're a router, this is your SNAT interface
NETWORKING_IP_EXTERNAL = '192.168.1.1'  # if you're a router, this is your SNAT address
DEFAULT_ROUTE = '192.168.1.1'
DEFAULT_DNS = '8.8.8.8'
DEFAULT_NTP = 'ntp.ubuntu.com'
DEFAULT_SYSLOG = '192.168.1.1'           # your remote syslog server
CMND_WHICH = '/usr/bin/which'

#### Files
FIREWALL_FILE = '/etc/firewall.sh'
RCLOCAL_FILE = '/etc/rc.local'
SYSCTL_FILE = '/etc/sysctl.conf'
CRONTAB_FILE = '/etc/crontab'
RESOLV_HEAD_FILE = '/etc/resolvconf/resolv.conf.d/head'

#### Logs that need rotating
SYSLOG_LOG = '/var/log/syslog'
HEAT_LOG = '/var/log/heat.log'

#### Command paths
CMND_GREP = %x(#{CMND_WHICH} grep).chomp
CMND_AWK = %x(#{CMND_WHICH} awk).chomp
CMND_SED = %x(#{CMND_WHICH} sed).chomp
CMND_CHMOD = %x(#{CMND_WHICH} chmod).chomp
CMND_CHOWN = %x(#x{CMND_WHICH} chown).chomp
CMND_CAT = %x(#x{CMND_WHICH} cat).chomp
CMND_IPTABLES = %x(#{CMND_WHICH} iptables).chomp
CMND_SYSCTL = %x(#{CMND_WHICH} sysctl).chomp
CMND_APTGET = %x(#{CMND_WHICH} apt-get).chomp
CMND_RESOLVCONF = %x(#{CMND_WHICH} resolvconf).chomp
CMND_NTPDATE = %x(#{CMND_WHICH} ntpdate).chomp
CMND_UPDATERCD = %x(#{CMND_WHICH} update-rc.d).chomp
CMND_SERVICE = %x(#{CMND_WHICH} service).chomp
CMND_ECHO = %x(#{CMND_WHICH} echo).chomp
CMND_UPDATERCD = %x(#{CMND_WHICH} update-rc.d).chomp

# chmod function tool
def chmod_tool(file,perms)
	print "[.] Making #{file} chmod #{perms}..\n"
	results = %x(#{CMND_CHMOD} #{perms} #{file})
	if results.match(/invalid|No such file or directory|not permitted/)
		print "[!] ERROR: Changing permissions on #{file} to #{perms} failed..\n#{results}\n"
		abort
	end
end

# grep function tool
def grep_tool(file,text)
	print "[.] Attempting to match #{text} from #{file}..\n"
	results = %x(#{CMND_GREP} \"#{text}\" #{file})
	( results.size > 0 ) ? true : false
end
	
# creates default rc.local file
def rclocal_create
	rclocal = ""
	rclocal << "#!/bin/sh -e\n"
	rclocal << "# Default rc.local file, created #{DATE}\n\n"
	rclocal << "# disable plymouth\n"
	rclocal << "/bin/rm -f /etc/init/plymouth* > /dev/null 2>&1\n\n"
	rclocal << "# shields up!\n"
	rclocal << "#{FIREWALL_FILE} 2>&1 >/dev/null\n\n"
	rclocal << "exit 0\n"

	print "[.] Writing #{RCLOCAL_FILE}..\n"
	File.open(RCLOCAL_FILE,"w") { |f| f.write(rclocal) }

	#chmod 700
	chmod_tool(RCLOCAL_FILE, 700)
end

# Setup Firewall.sh file
def firewall_up
	print "[+] Creating #{FIREWALL_FILE} script now..\n"
	firewall_sh = ""
	firewall_sh << "#!/bin/bash\n"
	firewall_sh << "# Builds basic firewall\n"
	firewall_sh << "# Assumes eth0 is input and eth0 is output\n\n"
	firewall_sh << "INFACE=#{NETWORKING_INTERFACE_INTERNAL}\n"
	firewall_sh << "OUTFACE=#{NETWORKING_INTERFACE_EXTERNAL}\n\n" if ROUTER
	firewall_sh << "# reset firewall state\n"
	firewall_sh << "echo \"Stopping firewall and allowing everyone...\"\n"
	firewall_sh << "iptables -F\n"
	firewall_sh << "iptables -X\n"
	firewall_sh << "iptables -t nat -F\n"
	firewall_sh << "iptables -t nat -X\n"
	firewall_sh << "iptables -t mangle -F\n"
	firewall_sh << "iptables -t mangle -X\n\n"
	firewall_sh << "# now build it up from scratch\n"
	firewall_sh << "echo \"Building firewall rules..\"\n"
	firewall_sh << "iptables -N LOGGING\n"
	firewall_sh << "iptables -t nat -A POSTROUTING -o $OUTFACE -j SNAT --to #{NETWORKING_IP_EXTERNAL}\n\n" if ROUTER
	firewall_sh << "# INPUT\n"
	firewall_sh << "iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT\n"
	firewall_sh << "iptables -A INPUT -i $INFACE -p tcp --dport 22 -m state --state NEW -j ACCEPT\n\n"
	firewall_sh << "# FORWARD\n"
	firewall_sh << "iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT\n" if ROUTER
	firewall_sh << "\n\n"
	firewall_sh << "# OUTPUT\n"
	firewall_sh << "iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT\n"
	firewall_sh << "iptables -A OUTPUT -p tcp --dport 22 -m state --state NEW -j ACCEPT\t#ssh\n"
	firewall_sh << "iptables -A OUTPUT -p tcp --dport 53 -m state --state NEW -j ACCEPT\t#dns\n"
	firewall_sh << "iptables -A OUTPUT -p udp --dport 53 -j ACCEPT\t#dns\n"
	firewall_sh << "iptables -A OUTPUT -p udp --dport 67 -j ACCEPT\t#dhcp\n"
	firewall_sh << "iptables -A OUTPUT -p tcp --dport 80 -m state --state NEW -j ACCEPT\t#http\n"
	firewall_sh << "iptables -A OUTPUT -p udp --dport 123 -m state --state NEW -j ACCEPT\t#ntp\n"
	firewall_sh << "iptables -A OUTPUT -p tcp --dport 443 -m state --state NEW -j ACCEPT\t#https\n"
	firewall_sh << "iptables -A OUTPUT -d #{DEFAULT_SYSLOG} -p udp --dport 514 -j ACCEPT\t#syslog\n" if ENABLE_SYSLOG
	firewall_sh << "\n\n"
	firewall_sh << "# Drop Everything Else\n"
	firewall_sh << "iptables -A INPUT -j LOG --log-prefix \"iptables INPUT DROP: \"\n"
	firewall_sh << "iptables -A FORWARD -j LOG --log-prefix \"iptables FORWARD DROP: \"\n"
	firewall_sh << "iptables -A OUTPUT -j LOG --log-prefix \"iptables OUTPUT DROP: \"\n"
	firewall_sh << "iptables -P INPUT DROP\n"
	firewall_sh << "iptables -P FORWARD DROP\n"
  firewall_sh << "iptables -P OUTPUT DROP\n"
	firewall_sh << "iptables -A FORWARD -i $OUTFACE -o $OUTFACE -j REJECT\n\n"
	firewall_sh << "echo \"Done!\"\n\n"

	print "[.] Writing script to #{FIREWALL_FILE}..\n"
	File.open(FIREWALL_FILE, "w") { |f| f.write(firewall_sh) }
	
	#chmod 700
	chmod_tool(FIREWALL_FILE, 700)

	print "[.] Executing #{FIREWALL_FILE}..\n"
	firewall_report = %x(#{FIREWALL_FILE})
	print "#{firewall_report}\n"
end

# disables ipv6 via sysctl
def ipv6_disable
	if grep_tool(SYSCTL_FILE,"^net.ipv6.conf.all.disable_ipv6 = 1")
		print "[.] IPv6 already disabled via #{SYSCTL_FILE}..\n"
	else

		ipv6 = "# ipv6 disable script-added\n"
		ipv6 << "net.ipv6.conf.all.disable_ipv6 = 1\n"
		ipv6 << "net.ipv6.conf.default.disable_ipv6 = 1\n"
		ipv6 << "net.ipv6.conf.lo.disable_ipv6 = 1\n\n"

		print "[+] Adding ipv6 disable lines to #{SYSCTL_FILE}..\n"
		File.open(SYSCTL_FILE, "a") { |f| f.write ipv6 }

		print "[.] Executing #{CMND_SYSCTL} -p to load..\n"
		results = %x(#{CMND_SYSCTL} -p )
		validation = 0

		begin
			validation = %x(#{CMND_CAT} /proc/sys/net/ipv6/conf/all/disable_ipv6).chomp.to_i
		rescue Errno::EACCES
			print "[!] No access to /proc/sys/net/ipv6/conf/all/disable_ipv6.. check it.\n"
		end

		if validation == 1
			print "[.] IPv6 successfully disabled..\n"
		else
			print "[!] IPv6 is not disabled, inspect #{SYSCTL_FILE} or rerun `sysctl -p` ..\n"
		end
	end
end

# enables IPv4 forwarding
def forwarding_enable
	if grep_tool(SYSCTL_FILE,"^net.ipv4.ip_forward = 1")
		print "[.] IP Forwarding already enabled via #{SYSCTL_FILE}..\n"
	else
		ipv4 = "# IPv4 forwarding enable script-added\n"
		ipv4 << "net.ipv4.ip_forward = 1\n\n"

		print "[+] Adding IPv4 Forwarding enable lines to #{SYSCTL_FILE}..\n"
		File.open(SYSCTL_FILE, "a") { |f| f.write ipv4 }

		print "[.] Executing #{CMND_SYSCTL} -p to load..\n"
		results = %x(#{CMND_SYSCTL} -p )
		validation = 0

		begin
			validation = %x(#{CMND_CAT} /proc/sys/net/ipv4/ip_forward).chomp.to_i
		rescue Errno::EACCES
			print "[!] No access to /proc/sys/net/ipv4/ip_forward.. check it.\n"
		end

		if validation == 1
			print "[.] IPv4 forwarding enabled..\n"
		else
			print "[!]IPv4 forwarding is not enabled, inspect #{SYSCTL_FILE} or rerun `sysctl -p` ..\n"
		end
	end
end

# ensures IPv4 forwarding is disabled
def forwarding_disable
	if !grep_tool(SYSCTL_FILE,"^net.ipv4.ip_forward = 1")
		print "[.] IP Forwarding already disabled via #{SYSCTL_FILE}..\n"
	else
		ipv4 = "# IPv4 forwarding disable script-added\n"
		ipv4 << "net.ipv4.ip_forward = 0\n\n"

		print "[+] Adding IPv4 Forwarding enable lines to #{SYSCTL_FILE}..\n"
		File.open(SYSCTL_FILE, "a") { |f| f.write ipv4 }

		print "[.] Executing #{CMND_SYSCTL} -p to load..\n"
		results = %x(#{CMND_SYSCTL} -p )
		validation = 1

		begin
			validation = %x(#{CMND_CAT} /proc/sys/net/ipv4/ip_forward).chomp.to_i
		rescue Errno::EACCES
			print "[!] No access to /proc/sys/net/ipv4/ip_forward.. check it.\n"
		end

		if validation == 0
			print "[.] IPv4 forwarding enabled..\n"
		else
			print "[!]IPv4 forwarding is not enabled, inspect #{SYSCTL_FILE} or rerun `sysctl -p` ..\n"
		end
	end
end

def update_os
	print "[.] Updating apt-get sources..\n"
	results = %x(#{CMND_APTGET} update)
	#print "#{results}\n"
	print "[.] Updating OS via apt-get update.\n"
	results = %x(#{CMND_APTGET} -y upgrade)
	#print "#{results}\n"
end

def install_haveged
	print "[.] Installing haveged..\n"
	results = %x(#{CMND_APTGET} -y install haveged)
	#print "#{results}\n"

	print "[.] Updating rc.d to start haveged..\n"
	results = %x(#{CMND_UPDATERCD} haveged enable 2345)
end

# install various heat packages for monitoring
def install_sensors
	print "[.] Installing smartctl tools, lm-sensors and hddtemp..\n"
	results = %x(#{CMND_APTGET} -y install smartmontools lm-sensors hddtemp )

	if results.match(/error|Unable to locate package/)
		print "[.] Unable to install lm-sensors or hddtemp.\n Output: #{results}..\n"
	end
end

# updates resolvconf to the proper nameserver for default
def update_resolv
	resolv = "nameserver #{DEFAULT_DNS}\n"
	
	print "[.] Updating #{RESOLV_HEAD_FILE}..\n"
	File.open(RESOLV_HEAD_FILE,"w") {|f| f.write(resolv) }

	print "[.] Setting proper permissions on #{RESOLV_HEAD_FILE}..\n"
	chmod_tool(RESOLV_HEAD_FILE,640)

	print "[.] Updating live conf via #{CMND_RESOLVCONF} -u .. \n"
	results = %x(#{CMND_RESOLVCONF} -u)
	sleep 5
	
	if results.size > 0
		print "[.] #{CMND_RESOLVCONF} -u failed for some reason.\n Output: #{results}..\n"
	end
end

# create default crontab
def update_crontab
	crontab = "SHELL=/bin/sh\n"
	crontab <<
"PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin\n\n"
	crontab << "# m h dom mon dow user	command\n"
	crontab << "17 *	* * *	root    cd / && run-parts --report /etc/cron.hourly\n"
	crontab << "25 6	* * *	root	test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/	cron.daily )\n"
	crontab << "47 6	* * 7	root	test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/	cron.weekly )\n"
	crontab << "52 6	1 * *	root	test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.monthly )\n\n"
	crontab << "# Administrivia\n"
	crontab << "0 * * * * root #{CMND_NTPDATE} #{DEFAULT_NTP} 2>&1 > /dev/null\n"
	crontab << "* * * * * root (date && sensors -f && hddtemp #{DEFAULT_HDD}) >> /var/log/heat.log 2>/dev/null\n"	

	print "[.] Updating #{CRONTAB_FILE} ..\n"
	File.open(CRONTAB_FILE, "w") {|f| f.write(crontab) }

	print "[.] Setting correct permissions on #{CRONTAB_FILE}..\n"
	chmod_tool(CRONTAB_FILE, 640)
end

# Install syslog-ng and point it at your default syslog collector
def install_syslogng
  print "[.] Installing syslog-ng..\n"
	results = %x(#{CMND_APTGET} -y install syslog-ng-core)
	
	print "[.] Adding remote syslog capabilities to server: #{DEFAULT_SYSLOG} .."
	results = %x(#{CMND_ECHO} -e "destination d_remote_net { udp("#{DEFAULT_SYSLOG}" port(514) log_fifo_size(1000)); };\nlog { source(s_src); destination(d_remote_net); };\n" > /etc/syslog-ng/conf.d/remote-syslog.conf)
	
	print "[.] Restarting syslog-ng server.."
	results = %x(#{CMND_SERVICE} syslog-ng restart)
end

# disable ntpd 
def disable_ntpd
	print "[.] Disabling ntpd..\n"
	results = %x(#{CMND_UPDATERCD} ntp disable)
end


#### Main
print "## Ubuntu 14.04 LTS Secure Script by Ryan C. Moon.. w00pw00p!\n"
print "* All custom files plus /etc/rc.local will be overwritten..\n"

# firewall
print "[*] Creating secure basic firewall..\n"
firewall_up()

# disable IPv6
print "[*] Disabling IPv6..\n"
ipv6_disable()

# disable forwarding
if ROUTER
	print "[*] Enabling IPv4 forwarding..\n"
	forwarding_enable()
else
	print "[*] Disabling IPv4 forwarding..\n"
	forwarding_disable()
end

# crontab
print "[*] Creating #{CRONTAB_FILE} ..\n"
update_crontab()

# update resolv.conf
print "[*] Setting nameservers and securint file..\n"
update_resolv()

# patch to current
print "[*] Patching to current via apt-get..\n"
update_os()

# add temperature detection
print "[*] Adding heat detection..\n"
install_sensors()
CMND_HDDTEMP = %x(#{CMND_WHICH} hddtemp).chomp
CMND_SENSORS = %x(#{CMND_WHICH} sensors).chomp

# install haveged
install_haveged()

# disable ntp
disable_ntpd()

# rc.local
print "[*] Creating #{RCLOCAL_FILE}..\n"
rclocal_create()

# syslog-ng
print "[*] Installing syslog-ng..\n"
install_syslogng() if ENABLE_SYSLOG

## Todos
# app armor profiles
# clean up log files via logrotate confs

# fin!
print "[!!] Done.. enjoy your new badly secured server..\n"

