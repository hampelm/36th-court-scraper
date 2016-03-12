require "awesome_print"
require 'dotenv'
require 'mechanize'
require 'ostruct'
require 'pg'

class Scraper
  def initialize
    Dotenv.load
    @conn = PG.connect(ENV['POSTGRES'])
    @conn.prepare('ins', 'insert into court (judge, date, time, case_or_ticket, case_link, name, action, court) values ($1, $2, $3, $4, $5, $6, $7, $8)')

    agent = Mechanize.new
    # agent.log = Logger.new(STDOUT)

    page = agent.get('http://jis.36thdistrictcourt.org/BSI_DocDisplay/')
    form = page.form('frmJISDocket')
    form.txtFRDktDate = '1/22/2016'
    form.txtTODktDate = '1/22/2016'
    form.lstFRDktTime = '0700'
    form.lstTODktTime = '0900'
    button = form.button_with(:value => 'Display Court Schedule')
    page = agent.submit(form, button)
    process(page)

    # List all the pages
    pages = page.css('.mypager table td')
    num_pages = pages.size / 2 # There are two page lists
    page_list = (2..num_pages).to_a
    puts "Page list " + page_list.to_s

    page_list.each do |num|
      form = page.form('frmJISSched')
      form['__EVENTTARGET'] = 'gvDocket'
      form['__EVENTARGUMENT'] = 'Page$' + num.to_s
      puts "Working on page " + num.to_s
      page = agent.submit(form)
      # puts page.body
      process(page)
      # sleep(2)
      # puts page.body
    end
  end

  def process(page)
    rows = page.css('table#gvDocket tr:not(.mypager)').map

    rows.each do |row|
      tds = row.css('td')
      if tds[0] \
        && tds[6] \
        && tds[0].text.strip != '1' \
        && tds[0].text.strip != 'Judge/Mag/PO/Courtrm'
      
        judge = tds[0].text.strip
        date = tds[1].text.strip
        time = tds[2].text.strip
        case_or_ticket = tds[3].text.strip
        case_link = tds[3].at_css('a')['href']
        name = tds[4].text.strip
        action = tds[5].text.strip
        court = tds[6].text.strip

        @conn.exec_prepared('ins', [judge, date, time, case_or_ticket, case_link, name, action, court])
      end
    end
  end
end

scraper = Scraper.new()
