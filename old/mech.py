from bs4 import BeautifulSoup
import mechanize

browser = mechanize.Browser()

browser.open('http://www.36thdistrictcourt.org/bsi_docdisplay/Default.aspx')
browser.select_form(name='frmJISDocket')
browser['txtFRDktDate'] = '1/22/2016'
browser['txtTODktDate'] = '1/22/2016'
browser['lstFRDktTime'] = ['0700',]
browser['lstTODktTime'] = ['0000',]

browser.submit(name='btnGO')

# id = gvDocket

soup = BeautifulSoup(browser.response().read(), 'html.parser')

docket = soup.find(id='gvDocket').find_all('tr')[1:]

'mypager'

cases = []
for row in docket:
  cells = row.find_all('td')
  data = {
    'judge': cells[0].get_text().strip(),
    'date': cells[1].get_text().strip(),
    'time': cells[2].get_text().strip(),
    'case_or_ticket': cells[3].get_text().strip(),
    'case_link': cells[3].find('a')['href'],
    'name': cells[4].get_text().strip(),
    'action': cells[5].get_text().strip(),
    'court': cells[6].get_text().strip()
  }
  print data
