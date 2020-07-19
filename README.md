# Selenium script

* First, run the following command-
  ```bash
  sudo chmod +x combine-ip-parallel-try.sh
  ```
* Then, enter your BrowserStack **Username** and **Key** on line number `20` and `21` respectively.

* For running locally, use the following command after running the chromedriver-
  ```bash
  ./combine-ip-parallel-try.sh
  ```

* For running a single session in BorwserStack, run the following command-
  ```bash
  ./combine-ip-parallel-try.sh --browserstack
  ```

* For running a single session in BrowserStack along with getting the IP and RTT, run the following command-
  ```bash
  ./combine-ip-parallel-try.sh --browserstack --ip-check
  ```

* For running multiple sessions in parallel, run the following command-
  ```bash
  ./combine-ip-parallel-try.sh --browserstack --ip-check --parallel
  ```
