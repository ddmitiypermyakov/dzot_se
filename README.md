Описание домашнего задания
1. Запустить nginx на нестандартном порту 3-мя разными способами:
•	переключатели setsebool;
•	добавление нестандартного порта в имеющийся тип;
•	формирование и установка модуля SELinux.
К сдаче:
•	README с описанием каждого решения (скриншоты и демонстрация приветствуются). 

2. Обеспечить работоспособность приложения при включенном selinux.
•	развернуть приложенный стенд https://github.com/mbfx/otus-linux-adm/tree/master/selinux_dns_problems; 
•	выяснить причину неработоспособности механизма обновления зоны (см. README);
•	предложить решение (или решения) для данной проблемы;
•	выбрать одно из решений для реализации, предварительно обосновав выбор;
•	реализовать выбранное решение и продемонстрировать его работоспособность


Порт TCP 4881 уже проброшен до хоста. SELinux включен.После запуска vagrant up

selinux: Complete!
    selinux: Job for nginx.service failed because the control process exited with error code.
    selinux: See "systemctl status nginx.service" and "journalctl -xe" for details.
    selinux: ● nginx.service - The nginx HTTP and reverse proxy server
    selinux:    Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
    selinux:    Active: failed (Result: exit-code) since Fri 2024-07-26 07:10:11 UTC; 31ms ago
    selinux:   Process: 8652 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
    selinux:   Process: 8640 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    selinux:
    selinux: Jul 26 07:10:11 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
    selinux: Jul 26 07:10:11 selinux nginx[8652]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
    selinux: Jul 26 07:10:11 selinux nginx[8652]: nginx: [emerg] bind() to [::]:4881 failed (13: Permission denied)
    selinux: Jul 26 07:10:11 selinux nginx[8652]: nginx: configuration file /etc/nginx/nginx.conf test failed
    selinux: Jul 26 07:10:11 selinux systemd[1]: nginx.service: Control process exited, code=exited status=1
    selinux: Jul 26 07:10:11 selinux systemd[1]: nginx.service: Failed with result 'exit-code'.
    selinux: Jul 26 07:10:11 selinux systemd[1]: Failed to start The nginx HTTP and reverse proxy server.

1.	Запуск nginx на нестандартном порту 3-мя разными способами
Метод 1
Проверяем файерволл
systemctl status firewalld
firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
   Active: active (running) since Fri 2024-07-26 07:07:16 UTC; 8min ago
     Docs: man:firewalld(1)
 Main PID: 766 (firewalld)
    Tasks: 2 (limit: 4614)
   Memory: 13.7M
   CGroup: /system.slice/firewalld.service
           └─766 /usr/libexec/platform-python -s /usr/sbin/firewalld --nofork --nopid

Jul 26 07:07:14 oracle8.localdomain systemd[1]: Starting firewalld - dynamic firewall daemon...
Jul 26 07:07:16 oracle8.localdomain systemd[1]: Started firewalld - dynamic firewall daemon.
Jul 26 07:07:17 oracle8.localdomain firewalld[766]: WARNING: AllowZoneDrifting is enabled. This is considered an insecu> 

systemctl status firewalld
systemctl stop firewalld
systemctl status firewalld

[root@selinux ~]# systemctl status firewalld
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
   Active: inactive (dead) since Fri 2024-07-26 07:17:19 UTC; 1s ago
     Docs: man:firewalld(1)
  Process: 766 ExecStart=/usr/sbin/firewalld --nofork --nopid $FIREWALLD_ARGS (code=exited, status=0/SUCCESS)
 Main PID: 766 (code=exited, status=0/SUCCESS)

Jul 26 07:07:14 oracle8.localdomain systemd[1]: Starting firewalld - dynamic firewall daemon...
Jul 26 07:07:16 oracle8.localdomain systemd[1]: Started firewalld - dynamic firewall daemon.
Jul 26 07:07:17 oracle8.localdomain firewalld[766]: WARNING: AllowZoneDrifting is enabled. This is considered an insecu>
Jul 26 07:17:16 selinux systemd[1]: Stopping firewalld - dynamic firewall daemon...
Jul 26 07:17:19 selinux systemd[1]: firewalld.service: Succeeded.
Jul 26 07:17:19 selinux systemd[1]: Stopped firewalld - dynamic firewall daemon.

конфигурация nginx настроена без ошибок:

nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful

Режим работы SElinux

[root@selinux ~]# getenforce 
Enforcing

Enforcing - SELinux будет блокировать запрещенную активность - 

Утилита audit2why покажет почему трафик блокируется. 
grep 1721977811.230:884 /var/log/audit/audit.log | audit2why
sy
Исходя из вывода утилиты, мы видим, что нам нужно поменять параметр nis_enabled. 
Включим параметр nis_enabled и перезапустим nginx: setsebool -P nis_enabled on
setsebool -P nis_enabled on
[root@selinux ~]# systemctl restart nginx
[root@selinux ~]# systemctl status  nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Fri 2024-07-26 07:28:42 UTC; 11s ago
  Process: 10239 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 10237 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 10234 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 10240 (nginx)
    Tasks: 3 (limit: 4614)
   Memory: 4.9M
   CGroup: /system.slice/nginx.service
           ├─10240 nginx: master process /usr/sbin/nginx
           ├─10241 nginx: worker process
           └─10242 nginx: worker process

Jul 26 07:28:42 selinux systemd[1]: nginx.service: Succeeded.
Jul 26 07:28:42 selinux systemd[1]: Stopped The nginx HTTP and reverse proxy server.
Jul 26 07:28:42 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Jul 26 07:28:42 selinux nginx[10237]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jul 26 07:28:42 selinux nginx[10237]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Jul 26 07:28:42 selinux systemd[1]: Started The nginx HTTP and reverse proxy server.
Првоеряем статус 
[root@selinux ~]# getsebool -a | grep nis_enabled
nis_enabled --> on

Все проверил, 
setsebool -P nis_enabled off
После отключения nis_enabled служба nginx снова не  запустилась.

Метод 2

Теперь разрешим в SELinux работу nginx на порту TCP 4881 c помощью добавления нестандартного порта в имеющийся тип:

[root@selinux ~]# semanage port -l | grep http
http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010
http_cache_port_t              udp      3130
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
pegasus_https_port_t           tcp      5989

Добавим порт в тип http_port_t: 
semanage port -a -t http_port_t -p tcp 4881
semanage port -l | grep  http_port_t
http_port_t                    tcp      4881, 80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
Рестарт nginx
systemctl restart nginx
[root@selinux ~]# systemctl restart nginx
[root@selinux ~]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Fri 2024-07-26 07:33:06 UTC; 7s ago
  Process: 10281 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 10278 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 10276 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 10282 (nginx)
    Tasks: 3 (limit: 4614)
   Memory: 5.0M
   CGroup: /system.slice/nginx.service
           ├─10282 nginx: master process /usr/sbin/nginx
           ├─10283 nginx: worker process
           └─10284 nginx: worker process

Jul 26 07:33:06 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Jul 26 07:33:06 selinux nginx[10278]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jul 26 07:33:06 selinux nginx[10278]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Jul 26 07:33:06 selinux systemd[1]: Started The nginx HTTP and reverse proxy server.

Работает

[root@selinux ~]# semanage port -d -t http_port_t -p tcp 4881
[root@selinux ~]# semanage port -l | grep  http_port_t
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
[root@selinux ~]# systemctl restart nginx
Job for nginx.service failed because the control process exited with error code.
See "systemctl status nginx.service" and "journalctl -xe" for details.
[root@selinux ~]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: failed (Result: exit-code) since Fri 2024-07-26 07:34:31 UTC; 31s ago
  Process: 10281 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 10302 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
  Process: 10300 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 10282 (code=exited, status=0/SUCCESS)

Jul 26 07:34:31 selinux systemd[1]: nginx.service: Succeeded.
Jul 26 07:34:31 selinux systemd[1]: Stopped The nginx HTTP and reverse proxy server.
Jul 26 07:34:31 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Jul 26 07:34:31 selinux nginx[10302]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jul 26 07:34:31 selinux nginx[10302]: nginx: [emerg] bind() to [::]:4881 failed (13: Permission denied)
Jul 26 07:34:31 selinux nginx[10302]: nginx: configuration file /etc/nginx/nginx.conf test failed
Jul 26 07:34:31 selinux systemd[1]: nginx.service: Control process exited, code=exited status=1
Jul 26 07:34:31 selinux systemd[1]: nginx.service: Failed with result 'exit-code'.
Jul 26 07:34:31 selinux systemd[1]: Failed to start The nginx HTTP and reverse proxy server.

Метод 3 Разрешим в SELinux работу nginx на порту TCP 4881 c помощью формирования и установки модуля SELinux:
grep nginx /var/log/audit/audit.log
Смотрим аудит
grep nginx /var/log/audit/audit.log | audit2allow -M nginx
******************** IMPORTANT ***********************
To make this policy package active, execute:

semodule -i nginx.pp

	Audit2allow сформировал модуль, и сообщил нам команду, с помощью которой можно применить данный модуль: semodule -i nginx.pp
[root@selinux ~]# systemctl start nginx
[root@selinux ~]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Fri 2024-07-26 07:38:08 UTC; 11s ago
  Process: 10326 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 10324 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 10322 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 10327 (nginx)
    Tasks: 3 (limit: 4614)
   Memory: 9.6M
   CGroup: /system.slice/nginx.service
           ├─10327 nginx: master process /usr/sbin/nginx
           ├─10328 nginx: worker process
           └─10329 nginx: worker process

Jul 26 07:38:08 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Jul 26 07:38:08 selinux nginx[10324]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jul 26 07:38:08 selinux nginx[10324]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Jul 26 07:38:08 selinux systemd[1]: Started The nginx HTTP and reverse proxy server.

Просмотр всех установленных модулей: semodule -l
Для удаления модуля воспользуемся командой: semodule -r nginx

semodule -r nginx
libsemanage.semanage_direct_remove_key: Removing last nginx module (no other nginx module exists at another priority).

2.	Обеспечение работоспособности приложения при включенном SELinux


Попробуем внести изменения в зону: 
[vagrant@client ~]$ nsupdate -k /etc/named.zonetransfer.key

> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
update failed: SERVFAIL
> quit

Смотрим логи Selinux Для этого воспользуемся утилитой audit2why:
sudo -i

[root@client ~]# cat /var/log/audit/audit.log | audit2why

Отсутствуют ошибки

Логи сервера
sudo -i 
cat /var/log/audit/audit.log | audit2why
В логах ошибка. В логах мы видим, что ошибка в контексте безопасности. Вместо типа named_t используется тип etc_t.
ls -laZ /etc/named

drw-rwx---. root named system_u:object_r:etc_t:s0       .
drwxr-xr-x. root root  system_u:object_r:etc_t:s0       ..
drw-rwx---. root named unconfined_u:object_r:etc_t:s0   dynamic
-rw-rw----. root named system_u:object_r:etc_t:s0       named.50.168.192.rev
-rw-rw----. root named system_u:object_r:etc_t:s0       named.dns.lab
-rw-rw----. root named system_u:object_r:etc_t:s0       named.dns.lab.view1
-rw-rw----. root named system_u:object_r:etc_t:s0       named.newdns.lab


Тут мы также видим, что контекст безопасности неправильный. Проблема заключается в том, что конфигурационные файлы лежат в другом каталоге. Посмотреть в каком каталоги должны лежать, файлы, чтобы на них распространялись правильные политики SELinux можно с помощью команды: sudo semanage fcontext -l | grep named

sudo semanage fcontext -l | grep named

Изменим тип контекста безопасности для каталога /etc/named: sudo chcon -R -t named_zone_t /etc/named
sudo chcon -R -t named_zone_t /etc/named

ls -laZ /etc/named
drw-rwx---. root named system_u:object_r:named_zone_t:s0 .
drwxr-xr-x. root root  system_u:object_r:etc_t:s0       ..
drw-rwx---. root named unconfined_u:object_r:named_zone_t:s0 dynamic
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.50.168.192.rev
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.dns.lab
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.dns.lab.view1
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.newdns.lab

Пробуем снова 
nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
> quit 

[vagrant@client ~]$ dig www.ddns.lab
; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.7 <<>> www.ddns.lab
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 52762
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 2

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;www.ddns.lab.          IN  A

;; ANSWER SECTION:
www.ddns.lab.       60  IN  A   192.168.50.15

;; AUTHORITY SECTION:
ddns.lab.       3600    IN  NS  ns01.dns.lab.

;; ADDITIONAL SECTION:
ns01.dns.lab.       3600    IN  A   192.168.50.10

Изменения применились. Все работает.





