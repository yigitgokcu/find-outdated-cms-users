#!/bin/bash

# To make things easier to read
BoldOn="\033[1m"
BoldOff="\033[22m"

# To handle directories/files with spaces in the name
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

echo
echo "Searching for installed CMS..."
echo

# Check what type of server it is, set the path appropriately
## If it's a Grid
if [[ -n "${SITE}" ]]; then
  search_path="/home/${SITE}/users/.home/domains/*/"
else
  # Exit the script if not run using sudo/root in a DV
  if [ "$(id -u)" != "0" ]; then
    echo "This script needs to run as root or sudo. Exiting..."
    exit 0
  else
    ## If it's a DV with cPanel
    if [[ -f "/usr/local/cpanel/version" ]]; then
      search_path="/home/*/"
    ## If it's a DV with Plesk or a DV Developer (no Plesk or cPanel)
    elif [[ -f "/usr/local/psa/version" ]] || [[ ! -f "/usr/local/psa/version" ]] && [[ ! -f "/usr/local/cpanel/version" ]]; then
      search_path="/var/www/"
    fi
  fi
fi

# Get a list of files to work with for each CMS
joomla_search=$(find $search_path -maxdepth 7 \( -iwholename '*/libraries/joomla/version.php' -o -iwholename '*/libraries/cms/version.php' -o -iwholename '*/libraries/cms/version/version.php' \))
wp_search=$(find $search_path -maxdepth 7 \( -iwholename '*/wp-includes/version.php' \))
drupal_search=$(find $search_path -maxdepth 7 \( -iwholename '*/modules/system/system.info' \))
magento_search=$(find $search_path -maxdepth 7 \( -iwholename '*/app/Mage.php' \))
opencart_search=$(find $search_path -maxdepth 7 \( -iwholename '/admin/index.php' \))
moodle_search=$(find $search_path -maxdepth 7 \( -iwholename '/version.php' \))
#phpbb_search=$(find $search_path -maxdepth 7 \( -iwholename '' \))

# WordPress
if [[ -z "${wp_search}" ]]; then
  echo 'No WordPress installs found!'
else
  # Get the latest version of WordPress and define it
  new_wp_ver=$(curl -s http://api.wordpress.org/core/version-check/1.5/ | head -n 4 | tail -n 1)
  for wp_path in ${wp_search}; do
    # For each WordPress define the WordPress's version as a temporary variable
    wp_version=$(grep '$wp_version =' ${wp_path} | cut -d\' -f2)
    # Check the installed WordPress version against the latest version
    if [[ ${wp_version//./} != ${new_wp_ver//./} ]]; then
      if [[ -z "${wp_header}" ]]; then
        # Let the user know what the latest version is
        echo -e "${BoldOn}WordPress - Latest version is $new_wp_ver${BoldOff}"
        wp_header=true
      fi
      echo "$(echo "${wp_path}" | sed 's/wp-includes\/version.php//g; s/users\/\.home\///g') = $wp_version"
      wp_found=true
    fi
  done
  if [[ -z "${wp_found}" ]]; then
    echo '**WordPress installs found but are all up to date!'
  fi
fi
echo

# Joomla
if [[ -z "${joomla_search}" ]]; then
  echo 'No Joomla installs found!'
else
  # Get the latest version of Joomla and define it
  new_joomla_ver=$(curl -s https://api.github.com/repos/joomla/joomla-cms/releases/latest | awk -F\" '/tag_name/ { print $4 }')
  for joomla_path in ${joomla_search}; do
    # For each Joomla define the Joomla's version as a temporary variable
    joomla_version="$(grep -E "var|const|public" "${joomla_path}" | awk -F\' '/RELEASE/{print$2}').$(grep -E "var|const|public" "${joomla_path}" | awk -F\' '/DEV_LEVEL/{print$2}')"
    # Check the installed Joomla version against the latest version
    if [[ ${joomla_version//./} != ${new_joomla_ver//./} ]]; then
      if [[ -z "${joomla_header}" ]]; then
        # Let the user know what the latest version is
        echo -e "${BoldOn}Joomla - Latest version is ${new_joomla_ver}${BoldOff}"
        joomla_header=true
      fi
      echo "$(echo "${joomla_path}" | sed 's/libraries\/.*.php//g; s/users\/\.home\///g') = ${joomla_version}"
      joomla_found=true
    fi
  done
  if [[ -z "${joomla_found}" ]]; then
    echo '**Joomla installs found but are all up to date!'
  fi
fi
echo

# Drupal
if [[ -z "${drupal_search}" ]]; then
  echo 'No Drupal installs found!'
else
  # Get the latest version of Drupal and define it
  # This first one is considered the latest but ready for production
  new_drupal_ver1=$(wget -qO- https://www.drupal.org/project/drupal | grep '<h4>Drupal core' | grep -v dev | head -n 1 | awk -F' ' '{print $3}' | awk -F'<' '{print $1}')
  # This second one is considered older but still up to date
  new_drupal_ver2=$(wget -qO- https://www.drupal.org/project/drupal | grep '<h4>Drupal core' | grep -v dev | head -n 2 | tail -n 1 | awk -F' ' '{print $3}' | awk -F'<' '{print $1}')
  for drupal_path in ${drupal_search}; do
    # For each Drupal define the Drupal's version as a temporary variable
    drupal_version=$(grep "version = \"" ${drupal_path} | cut -d '"' -f2)
    # Check the installed Drupal version against the latest version
    if [[ ${drupal_version//./} != ${new_drupal_ver1//./} ]] && [[ ${drupal_version//./} != ${new_drupal_ver2//./} ]]; then
      if [[ -z "${drupal_header}" ]]; then
        # Let the user know what the latest version is
        echo -e "${BoldOn}Drupal - Latest version is ${new_drupal_ver1}, stable version is ${new_drupal_ver2}${BoldOff}"
        drupal_header=true
      fi
      echo $(echo "$drupal_path" | sed 's/modules\/system\/system\.info//g; s/users\/\.home\///g') = "$drupal_version"
      drupal_found=true
    fi
  done
  if [[ -z "${drupal_found}" ]]; then
    echo '**Drupal installs found but are all up to date!'
  fi
fi
echo

# phpBB
if [[ -z "${phpbb_search}" ]]; then
  echo 'No phpBB installs found!'
else
  # Get the latest version of phpBB and define it
  new_phpbb_ver=$(curl -s https://api.github.com/repos/phpbb/phpbb/tags | awk -F'"' '/name/ {print $4}' | awk -F'-' '!/-[A-Za-z]/ {print $0}' | awk -F'-' 'NR==2{print $2}')
  for phpbb_path in ${phpbb_search}; do
    # For each phpBB define the phpBB's version as a temporary variable
    phpbb_version=$(grep -H "version.=." ${phpbb_path} | awk 'NR==1{print $3}')
    # Check the installed phpBB version against the latest version
    if [[ ${phpbb_version//./} != ${new_phpbb_ver//./} ]]; then
      if [[ -z "${phpbb_header}" ]]; then
        # Let the user know what the latest version is
        echo -e "${BoldOn}phpBB - Latest version is ${new_phpbb_ver}${BoldOff}"
        phpbb_header=true
      fi
      echo "$(echo "$phpbb_path" | sed 's/styles\/prosilver\/style.cfg//g; s/users\/\.home\///g') = "$phpbb_version""
      phpbb_found=true
    fi
  done
  if [[ -z "${phpbb_found}" ]]; then
    echo '**phpBB installs found but are all up to date!'
  fi
fi
echo

# Magento
if [[ -z "${magento_search}" ]]; then
  echo 'No Magento installs found!'
else
  # Get the latest version of Magento and define it
  new_magento_ver=$(curl -s https://api.github.com/repos/magento/magento2/tags | awk -F'"' '/name/ {print $4}' | awk -F'-' '!/-[A-Za-z]/ {print $0}' | head -1)
  for magento_path in ${magento_search}; do
    # For each Magento define the Magento's version as a temporary variable
    magento_version=$(grep -A 4 'return array(' ${magento_path} | grep -Eo '[0-9]' | xargs | sed 's/ /./g')
    # Check the installed Magento version against the latest version
    if [[ ${magento_version//./} != ${new_magento_ver//./} ]]; then
      if [[ -z "${magento_header}" ]]; then
        # Let the user know what the latest version is
        echo -e "${BoldOn}Magento - Latest version is ${new_magento_ver}${BoldOff}"
        magento_header=true
      fi
      echo "$(echo "$magento_path" | sed 's/app\/Mage.php//g; s/users\/\.home\///g') = "$magento_version""
      magento_found=true
    fi
  done
  if [[ -z "${magento_found}" ]]; then
    echo '**Magento installs found but are all up to date!'
  fi
fi
echo

# Opencart
if [[ -z "${opencart_search}" ]]; then
  echo 'No Opencart installs found!'
else
  # Get the latest version of Opencart and define it
  new_opencart_ver=$(curl -s https://api.github.com/repos/opencart/opencart/tags | head -3 | awk -F'"' '/name/ {print $4}')
  for opencart_path in ${opencart_search}; do
    # For each Opencart define the Opencart's version as a temporary variable
    opencart_version=$(grep VERSION "${opencart_path}" | awk -F"'" '{print $4}')
    # Check the installed Opencart version against the latest version
    if [[ ${opencart_version//./} != ${new_opencart_ver//./} ]]; then
      if [[ -z "${opencart_header}" ]]; then
        # Let the user know what the latest version is
        echo -e "${BoldOn}Opencart - Latest version is ${new_opencart_ver}${BoldOff}"
        opencart_header=true
      fi
      echo "$(echo "$opencart_path" | sed 's/upload\/index.php//g; s/users\/\.home\///g') = "$opencart_version""
      opencart_found=true
    fi
  done
  if [[ -z "${opencart_found}" ]]; then
    echo '**Opencart installs found but are all up to date!'
  fi
fi
echo

# Moodle
if [[ -z "${moodle_search}" ]]; then
  echo 'No Moodle installs found!'
else
  # Get the latest version of Moodle and define it
  new_moodle_ver=$(curl -s "https://git.moodle.org/gw?p=moodle.git;a=tags" | grep "list name" | head -1 | sed 's/\(.*\)>v\(.*\)<\/a>\(.*\)/\2/g')
  for moodle_path in ${moodle_search}; do
    # For each Moodle define the Moodle's version as a temporary variable
    if [[ -z "$(moodle_version=$(grep VERSION $moodle_path | awk -F"'" '{print $4}'))" ]]; then
      moodle_version=$(awk -F"'" '/\$release/ {print $2}' "${moodle_path}" | awk '{print $1}')
    fi
    # Check the installed Moodle version against the latest version
    if [[ ${moodle_version//./} != ${new_moodle_ver//./} ]]; then
      if [[ -z "${moodle_header}" ]]; then
        # Let the user know what the latest version is
        echo -e "${BoldOn}Moodle - Latest version is ${new_moodle_ver}${BoldOff}"
        moodle_header=true
      fi
      echo "$(echo "${moodle_path}" | sed 's/version.php//g; s/users\/\.home\///g') = "$moodle_version""
      moodle_found=true
    fi
  done
  if [[ -z "${moodle_found}" ]]; then
    echo '**Moodle installs found but are all up to date!'
  fi
fi
echo

IFS=$SAVEIFS

# Delete .txt files older than 4 week
find /path/to/outdated_cms_users/ -name "*.txt" -type f -mtime +30 -exec rm -f {} \;
