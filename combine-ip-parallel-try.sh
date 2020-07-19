#!/bin/bash

# 1. First, it is a shell script to launch a selenium session locally (i.e. on your system) on Chrome. Download and run the latest selenium JAR and interact with it by using `curl` commands. The script should go to google and search for your name and then fetch and print the page title on the console.
# 2. Now I made minimal modifications in the previous script to take a command line flag --browserstack. If this flag is provided then the session should run on BrowserStack. For now, run it on the Chrome 65 on OS X Sierra; also pass appropriate build name, so that all your sessions are inside one build.
# 3. Then I added a flag --ip-check, which figures out the IP Address of the machine where your Selenium session runs on BrowserStack and then prints the RTT to that IP.
# 4. After that, I am trying to add a command line argument --parallel. The default value is 1. The different sessions should have the same build name but different session names. So, --ip-check --parallel will print the RTT times to two different BrowserStack machines(terminals).
# to add diffrent os-version choices for parallel scanning, modify "os_choices" variable and and the desired os version with a "-" as delimiter.
# eg. for OS X Mojave version you should add "OS X-Mojave" to the "os_choices" array, It will be  os_choices=("OS X-Mojave" "Windows-10" "OS X-Sierra")

# finally in order to scan with multiple os_choices in parallel, use --parallel argument,
# eg. ./combine-ip-parallel.sh --browserstack --ip-check --parallel THE FIRST TWO ARGUMENTS ARE MANDATORY!

# Ensure that --ip-check and --parallel-threads can only by used if  --browserstack is passed and that the time limit is adhered to.
# RTT = minimum Round Trip Time in ms

bstack_flag="$1"
bstack="--browserstack"
ip="--ip-check"
parallel="--parallel"
username=""
key=""
api_url="https://$username:$key@hub-cloud.browserstack.com/wd/hub/session"

os_choices=("OS X-Sierra" "Windows-10" "Windows-8.1" "OS X-Mojave" "Windows-8")
function split() {
  IFS='-'
  read -ra ADDR <<< "$1"
  OS_VERSION=()
  for i in "${ADDR[@]}"; do
    OS_VERSION+=($i)
  done
}
function session_browserstack() {
  echo "Session started on BrowserStack"
  sess=$(curl -XPOST -s $api_url -d '{"desiredCapabilities":{
  "os" : "Windows",
  "os_version" : "10",
  "browserName" : "Chrome",
  "browser_version" : "65.0",
  "build" : "Build-curl-try",
  "browserstack.local" : "false",
  "browserstack.selenium_version" : "3.141.59",
  "browserstack.networkLogs" : "true",
  "browserstack.user" : "$username",
  "browserstack.key" : "$key" }}' | jq -r '.sessionId')

  cons_url="$api_url/$sess"
}

function session_ip_check() {
  OS=$1
  printf "\n"
  if [ "$OS" ]; then
    printf "Finding IP Address of machine and starting session on BrowserStack on $OS \n"
    split "$OS"
    desired_cap='{"desiredCapabilities":{
    "os" : "'${OS_VERSION[0]}'",
    "os_version" : "'${OS_VERSION[1]}'",
    "browserName" : "Chrome",
    "browser_version" : "65.0",
    "build" : "Build-curl-try",
    "browserstack.local" : "false",
    "browserstack.selenium_version" : "3.141.59",
    "browserstack.networkLogs" : "true",
    "browserstack.user" : "'$username'",
    "browserstack.key" : "'$key'" }}'
  else
    OS="OS X-Sierra"
    printf "Finding IP Address of machine and starting session on BrowserStack on OS X-Sierra \n"
    desired_cap='{"desiredCapabilities":{
    "os" : "OS X",
    "os_version" : "Sierra",
    "browserName" : "Chrome",
    "browser_version" : "65.0",
    "build" : "Build-curl-try",
    "browserstack.local" : "false",
    "browserstack.selenium_version" : "3.141.59",
    "browserstack.networkLogs" : "true",
    "browserstack.user" : "'$username'",
    "browserstack.key" : "'$key'" }}'
  fi
  
  sess=$(curl -XPOST -s "$api_url" -d "$desired_cap"  | jq -r '.sessionId')
  
  cons_url="$api_url/$sess"

  url_sess_ip="$cons_url/url"

  element_sess_ip="$cons_url/element"

  start_time="$(date -u +%s.%N)"
  url_ip=$(curl -XPOST -s "$url_sess_ip" -d '{"url":"https://ifconfig.me"}')
  end_time="$(date -u +%s.%N)"
  rtt="$(bc <<<"$end_time-$start_time")"
  rtt_ms="$(bc <<<"$rtt*1000")"
  echo "$rtt_ms ms for $OS"
  element_inp_ip=$(curl -s "$element_sess_ip" -d '{"using":"id", "value":"ip_address"}' | jq -r '.value.ELEMENT')

  element_inp_sess_ip="$cons_url/element/$element_inp_ip/text"

  val_inp_ip=$(curl -s "$element_inp_sess_ip" | jq -r '.value')

  echo "$val_inp_ip  $OS"
}

function run_tests() {
  if [[ "$1"  && "$1" == "ip-check" ]]; then
    session_ip_check
  elif [[ "$1"  && "$1" == "browserstack" ]]; then
    session_browserstack
  elif [[ "$1"  && "$1" == "locally" ]]; then
    :
  else  
    session_ip_check "$1"
  fi
  url_sess="$cons_url/url"
  element_sess="$cons_url/element"

  url=$(curl -XPOST -s "$url_sess" -d '{"url":"https://www.google.com"}')

  element_inp=$(curl -s "$element_sess" -d '{"using":"name", "value":"q"}' | jq -r '.value.ELEMENT')

  element_inp_sess="$cons_url/element/$element_inp/value"

  val_inp=$(curl -XPOST -s "$element_inp_sess" -d '{"value":["Sayak Kundu"]}')

  button_inp=$(curl -s "$element_sess" -d '{"using":"name", "value":"btnK"}' | jq -r '.value.ELEMENT')
  button_inp_sess="$cons_url/element/$button_inp/submit"

  click_inp=$(curl -XPOST -s "$button_inp_sess")

  title_sess="$cons_url/title"

  title=$(curl -s "$title_sess" | jq -r '.value')

  echo "$title"

  delete=$(curl -XDELETE -s  "$cons_url")

  echo "Session deleted"

}

if [[ $# == 1 && "$1" == "$bstack" ]]; then
    run_tests browserstack
elif [[ $# == 2 && "$1" == "$bstack" && "$2" == "$ip" ]]; then
    run_tests ip-check
elif [[ $# == 3 && "$1" == "$bstack" && "$2" == "$ip" && "$3" == "$parallel" ]]; then
  for i in "${os_choices[@]}"; do
    run_tests "$i" &
  done
else
  echo "Session started locally"
  sess=$(curl -XPOST -s http://localhost:9515/session -d '{"desiredCapabilities":{"browserName":"chrome"}}' | jq -r '.sessionId')
  cons_url="http://localhost:9515/session/$sess"  
  run_tests locally
fi

