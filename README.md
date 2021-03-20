#### A bash script to find cPanel or Plesk accounts that using vulnerable versions of various CMSs, such as Wordpress, Joomla etc... and send report as email. This is useful for securing accounts. Especially in shared hosting environments.

 * Create a directory for store txt files and script itself. For example, ```/path/to/outdated_cms_users/``` 
 * Make sure that your script has the appropriate executable permission ```chmod +x /path/to/outdated_cms_users/find_outdated_cms_users.sh```
 * Add a cron job if you want to receive reports continuously. For example, ```0 12 * * 5 /path/to/outdated_cms_users/find_outdated_cms_users.sh > /path/to/outdated_cms_users/`date +"%Y-%m-%d"`-outdated_cms_users.txt | mailx -a /path/to/outdated_cms_users/`date +"%Y-%m-%d"`-oudated_cms_users.txt -s "Outdated CMS softwares on `hostname`  " email address  < /dev/null```
