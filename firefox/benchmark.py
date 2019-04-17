import time
import re
import urllib
import json
import sys 
import os
import select

from subprocess import check_output

from selenium.webdriver import Firefox, FirefoxProfile
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.support import expected_conditions as expected
from selenium.webdriver.support.wait import WebDriverWait


if __name__ == "__main__":
    options = Options()
    options.add_argument('-headless')

    profile = FirefoxProfile()
    profile.DEFAULT_PREFERENCES['frozen']['network.http.spdy.enabled.http2'] = False
    # profile.accept_untrusted_certs = True
    driver = Firefox(firefox_binary='/usr/local/bin/firefox', options=options, 
            firefox_profile=profile)
    wait = WebDriverWait(driver, timeout=120)
    driver.get('http://localhost:8000/kraken-1.1/driver.html')
    pids = list(map(int, check_output(["pgrep", "firefox"]).split("\n")))

    for pid in pids:
        print("Starting checkpoint for {}".format(pid))
        check_output(["./slsctl", "ckptstart", "-p", str(pid), "-t", "1000", "-f", str(pid) + ".sls"])
        print("Started checkpoint for {}".format(pid))

    wait.until(lambda driver : "results" in driver.current_url)

    for pid in pids:
        print("Stopping checkpoint for {}".format(pid))
        check_output(["./slsctl", "ckptstop", "-p", str(pid)])
        print("Stopped checkpoint for {}".format(pid))

    # elapsed = time.time() - start
    values = urllib.parse.unquote(driver.current_url.split('?')[1]) 
    vals = json.loads(values)
    runtime = 0
    for key, v in vals.items():
        if (key != "v"):  
            runtime += sum(list(map(int, v)))
    print(runtime)
    # while sys.stdin in select.select([sys.stdin], [], [], 0)[0]:
        # line = sys.stdin.readline()
        # if line:
    driver.close()
    driver.quit()
    exit()
