import time
import re
import urllib
import json
import sys 
import os
import select
import argparse

from subprocess import check_output

from selenium.webdriver import Firefox, FirefoxProfile
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.support import expected_conditions as expected
from selenium.webdriver.support.wait import WebDriverWait


def run(driver, wait, options, stop):
    print("Run Started")
    driver.get('http://localhost:8000/kraken-1.1/driver.html')
    pids = list(map(int, (check_output(["pgrep", "firefox"]).decode("utf-8").split("\n")[0:-1])))
    print(pids)

    if not stop:
        if options.sls:
            for pid in pids:
                check_output(["./slsctl", "ckptstart", "-p", str(pid), "-t", options.t[0], "-f", str(pid) + ".sls"])
                print("Checkpoint started {}".format(pid))

    wait.until(lambda driver : "results" in driver.current_url)

    if stop:
        if options.sls:
            for pid in pids:
                check_output(["./slsctl", "ckptstop", "-p", str(pid)])
                print("Checkpoint stopped {}".format(pid))

    values = urllib.parse.unquote(driver.current_url.split('?')[1]) 
    vals = json.loads(values)
    runtime = 0
    for key, v in vals.items():
        if (key != "v"):  
            runtime += sum(list(map(int, v)))
    return runtime

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Firefox benchmark for sls')
    parser.add_argument('--sls', action='store_true')
    parser.add_argument('-t', default=1000)
    parser.add_argument('--single-process', action='store_true')
    args = parser.parse_args(sys.argv[1:])

    options = Options()
    options.add_argument('-headless')
    profile = FirefoxProfile()
    profile.DEFAULT_PREFERENCES['frozen']['network.http.spdy.enabled.http2'] = False
    if args.single_process:
        profile.DEFAULT_PREFERENCES['frozen']['browser.tabs.remote.autostart'] = False
        profile.DEFAULT_PREFERENCES['frozen']['autostarter.privatebrowsing.autostart'] = False
    driver = Firefox(firefox_binary='/usr/local/bin/firefox', options=options, 
            firefox_profile=profile)
    wait = WebDriverWait(driver, timeout=120000)
    print("Driver started")
    print(run(driver, wait, args, False))
    print(run(driver, wait, args, True))
    driver.close()
    time.sleep(10)
    driver.quit()
    exit()
