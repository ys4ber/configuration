# this script is used to login to any website using python

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.common.exceptions import NoSuchElementException
from termcolor import colored

driver = webdriver.Chrome()

driver.get("https://the-website.com/login") # specify the endpoint of the login page

driver.find_element(By.NAME, "username").send_keys("your_username")
driver.find_element(By.NAME, "password").send_keys("your_password")
driver.find_element(By.NAME, "password").send_keys(Keys.RETURN)

# print("Login successful!")
try:
    driver.find_element(By.XPATH, "//div[contains(text(), 'Logout')]")
    print(colored("Login successful!", "green"))
except NoSuchElementException:
    print(colored("Login failed!", "red"))

driver.quit()