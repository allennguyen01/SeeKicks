from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.wait import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import pandas as pd


if __name__ == '__main__':
    table = pd.read_csv('C:\\Users\\mttra\\PycharmProjects\\sneakers\\labels_with_links.csv')

    driver = webdriver.Chrome()
    # table.to_csv(path_or_buf='labels_with_links.csv', columns={'id', 'name', 'link'}, index=False)

    j = 0
    while table.loc[j, "link"] != 'x':
        j += 1
    print(j)
    for i in range(j, 899):
        table = pd.read_csv('C:\\Users\\mttra\\PycharmProjects\\sneakers\\labels_with_links.csv')
        # random_wait = randrange(5) + 3
        # t ime.sleep(2)
        name = table.loc[i].at["name"]

        driver.get('https://www.google.com/search?q="stockx.com"+' + name)

        try:
            element = WebDriverWait(driver, 1000).until(
               EC.presence_of_element_located((By.LINK_TEXT, "Settings"))
           )
        finally:
            # driver.quit()
            print(end='')
            # break

        stockx_url = driver.find_element_by_xpath('//div[@class="yuRUbf"]//a[@href]').get_attribute("href")
        table.loc[i, "link"] = stockx_url
        table.to_csv(path_or_buf='labels_with_links.csv', columns={'id', 'name', 'link'}, index=False)
        if i % 25 == 0:
            print('done with ' + str(i) + ' shoes...')
        # driver.quit()
    print('DONE!')