#!/bin/sh
set -eu
export TERM=xterm
# Bash Colors
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
white=`tput setaf 7`
bold=`tput bold`
reset=`tput sgr0`
separator=$(echo && printf '=%.0s' {1..100} && echo)
# Logging Finctions
log() {
  if [[ "$@" ]]; then echo "${bold}${green}[LOG `date +'%T'`]${reset} $@";
  else echo; fi
}
warning() {
  echo "${bold}${yellow}[WARNING `date +'%T'`]${reset} ${yellow}$@${reset}";
}
error() {
  echo "${bold}${red}[ERROR `date +'%T'`]${reset} ${red}$@${reset}";
}
create_db() {
  mysql -u ${ZS_DBUser} -p${ZS_DBPassword} -h ${ZS_DBHost} -P ${ZS_DBPort} -e "CREATE DATABASE IF NOT EXISTS ${ZS_DBName} CHARACTER SET utf8;"
  mysql -u ${ZS_DBUser} -p${ZS_DBPassword} -h ${ZS_DBHost} -P ${ZS_DBPort} -e "GRANT ALL ON ${ZS_DBName}.* TO '${ZS_DBUser}'@'%' identified by '${ZS_DBPassword}';"
  mysql -u ${ZS_DBUser} -p${ZS_DBPassword} -h ${ZS_DBHost} -P ${ZS_DBPort} -e "flush privileges;"
}
import_zabbix_db() {
  mysql -u ${ZS_DBUser} -p${ZS_DBPassword} -h ${ZS_DBHost} -P ${ZS_DBPort} -D ${ZS_DBName} < ${ZABBIX_SQL_DIR}/schema.sql
  mysql -u ${ZS_DBUser} -p${ZS_DBPassword} -h ${ZS_DBHost} -P ${ZS_DBPort} -D ${ZS_DBName} < ${ZABBIX_SQL_DIR}/images.sql
  mysql -u ${ZS_DBUser} -p${ZS_DBPassword} -h ${ZS_DBHost} -P ${ZS_DBPort} -D ${ZS_DBName} < ${ZABBIX_SQL_DIR}/data.sql
}
logging() {
  mkdir -p /var/log/zabbix
  chmod 777 /var/log/zabbix
  touch /var/log/zabbix/zabbix_server.log /var/log/zabbix/zabbix_agentd.log
  chmod 777 /var/log/zabbix/zabbix_server.log /var/log/zabbix/zabbix_agentd.log
}
system_pids() {
  touch /var/run/zabbix_server.pid /var/run/zabbix_agentd.pid /var/run/zabbix_java.pid
  chmod 777 /var/run/zabbix_server.pid /var/run/zabbix_agentd.pid /var/run/zabbix_java.pid
}
fix_permissions() {
  getent group zabbix || groupadd zabbix
  getent passwd zabbix || useradd -g zabbix -M zabbix
  chown -R zabbix:zabbix /usr/local/etc/
  chown -R zabbix:zabbix /usr/local/src/zabbix/
  mkdir -p /usr/local/src/zabbix/frontends/php/conf/
  chmod 777 /usr/local/src/zabbix/frontends/php/conf/
  chmod u+s `which ping`
}
update_config() {
  sed -i 's#=ZS_ListenPort#='${ZS_ListenPort}'#g' /usr/local/etc/zabbix_server.conf
  if [ "$ZS_SourceIP" != "" ]; then
    echo SourceIP=${ZS_SourceIP} >> /usr/local/etc/zabbix_server.conf
  fi
  sed -i 's#=ZS_LogFileSize#='${ZS_LogFileSize}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_LogFile#='${ZS_LogFile}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_DebugLevel#='${ZS_DebugLevel}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_PidFile#='${ZS_PidFile}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_DBHost#='${ZS_DBHost}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_DBName#='${ZS_DBName}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_DBSchema#='${ZS_DBSchema}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_DBUser#='${ZS_DBUser}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_DBPassword#='${ZS_DBPassword}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_DBSocket#='${ZS_DBSocket}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_DBPort#='${ZS_DBPort}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_StartPollersUnreachable#='${ZS_StartPollersUnreachable}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_StartPollers#='${ZS_StartPollers}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_StartTrappers#='${ZS_StartTrappers}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_StartPingers#='${ZS_StartPingers}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_StartDiscoverers#='${ZS_StartDiscoverers}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_StartHTTPPollers#='${ZS_StartHTTPPollers}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_StartTimers#='${ZS_StartTimers}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_JavaGatewayPort#='${ZS_JavaGatewayPort}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_JavaGateway#='${ZS_JavaGateway}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_StartJavaPollers#='${ZS_StartJavaPollers}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_StartVMwareCollectors#='${ZS_StartVMwareCollectors}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_VMwareFrequency#='${ZS_VMwareFrequency}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_VMwarePerfFrequency#='${ZS_VMwarePerfFrequency}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_VMwareCacheSize#='${ZS_VMwareCacheSize}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_VMwareTimeout#='${ZS_VMwareTimeout}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_SNMPTrapperFile#='${ZS_SNMPTrapperFile}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_StartSNMPTrapper#='${ZS_StartSNMPTrapper}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_ListenIP#='${ZS_ListenIP}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_HousekeepingFrequency#='${ZS_HousekeepingFrequency}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_MaxHousekeeperDelete#='${ZS_MaxHousekeeperDelete}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_SenderFrequency#='${ZS_SenderFrequency}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_CacheSize#='${ZS_CacheSize}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_CacheUpdateFrequency#='${ZS_CacheUpdateFrequency}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_StartDBSyncers#='${ZS_StartDBSyncers}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_HistoryCacheSize#='${ZS_HistoryCacheSize}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_TrendCacheSize#='${ZS_TrendCacheSize}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_HistoryTextCacheSize#='${ZS_HistoryTextCacheSize}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_ValueCacheSize#='${ZS_ValueCacheSize}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_Timeout#='${ZS_Timeout}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_TrapperTimeout#='${ZS_TrapperTimeout}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_UnreachablePeriod#='${ZS_UnreachablePeriod}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_UnavailableDelay#='${ZS_UnavailableDelay}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_UnreachableDelay#='${ZS_UnreachableDelay}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_AlertScriptsPath#='${ZS_AlertScriptsPath}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_ExternalScripts#='${ZS_ExternalScripts}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_FpingLocation#='${ZS_FpingLocation}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_Fping6Location#='${ZS_Fping6Location}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_SSHKeyLocation#='${ZS_SSHKeyLocation}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_LogSlowQueries#='${ZS_LogSlowQueries}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_TmpDir#='${ZS_TmpDir}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_StartProxyPollers#='${ZS_StartProxyPollers}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_ProxyConfigFrequency#='${ZS_ProxyConfigFrequency}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_ProxyDataFrequency#='${ZS_ProxyDataFrequency}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_AllowRoot#='${ZS_AllowRoot}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_User#='${ZS_User}'#g' /usr/local/etc/zabbix_server.conf
  if [ "$ZS_Include" != "" ]; then
    echo Include=${ZS_Include} >> /usr/local/etc/zabbix_server.conf
  fi
  sed -i 's#=ZS_SSLCertLocation#='${ZS_SSLCertLocation}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_SSLKeyLocation#='${ZS_SSLKeyLocation}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_SSLCALocation#='${ZS_SSLCALocation}'#g' /usr/local/etc/zabbix_server.conf
  sed -i 's#=ZS_LoadModulePath#='${ZS_LoadModulePath}'#g' /usr/local/etc/zabbix_server.conf
  if [ "$ZS_LoadModule" != "" ]; then
    echo LoadModule=${ZS_LoadModule} >> /usr/local/etc/zabbix_server.conf
  fi
  sed -i 's/ZS_DBHost/'${ZS_DBHost}'/g' /usr/local/src/zabbix/frontends/php/conf/zabbix.conf.php
  sed -i 's/ZS_DBUser/'${ZS_DBUser}'/g' /usr/local/src/zabbix/frontends/php/conf/zabbix.conf.php
  sed -i 's/ZS_DBPassword/'${ZS_DBPassword}'/g' /usr/local/src/zabbix/frontends/php/conf/zabbix.conf.php
  sed -i 's/ZS_DBPort/'${ZS_DBPort}'/g' /usr/local/src/zabbix/frontends/php/conf/zabbix.conf.php
  sed -i 's/ZS_DBName/'${ZS_DBName}'/g' /usr/local/src/zabbix/frontends/php/conf/zabbix.conf.php

  sed -i 's/PHP_TIMEZONE/'${PHP_TIMEZONE}'/g' /etc/php.d/zz-zabbix.ini
}
####################### End of default settings #######################
# Zabbix default sql files 
ZABBIX_SQL_DIR="/usr/local/src/zabbix/database/mysql"
log "Preparing server configuration"
update_config
log "Config updated."
log "Enabling Logging and pid management."
logging
system_pids
fix_permissions
log "Done"
log "Checking if Database exists or fresh install"
if ! mysql -u ${ZS_DBUser} -p${ZS_DBPassword} -h ${ZS_DBHost} -P ${ZS_DBPort} -e "use zabbix;"; then
  warning "Zabbix DB doesn't exists. Installing and importing default settings"
  log `create_db`
  log "Database and user created. Importing Default SQL"
  log `import_zabbix_db`
  log "Import Finished. Starting"
else 
  log "Zabbix DB Exists. Starting server."
fi
# TODO wait for zabbix-server start
#python /config/pyzabbix.py 2>/dev/null
zabbix_agentd -c /usr/local/etc/zabbix_agentd.conf
