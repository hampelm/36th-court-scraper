require 'rspec'
require 'rubygems'
require 'capybara'
require 'capybara-webkit'
require 'capybara/dsl'

include RSpec::Matchers

Capybara.run_server = false
Capybara.current_driver = :webkit
Capybara.app_host = 'http://www.36thdistrictcourt.org'

Capybara::Webkit.configure do |config|
  config.allow_unknown_urls
end

module MyCapybaraScraper
  class Scrape
    include Capybara::DSL

    def parse
    end

    def is_current_page(element)
      puts "CHECKING " + element.text
      begin
        element.find('span')
      rescue Capybara::ElementNotFound
        puts "YES! Click the next link."
        return true
      end

      begin
        element.find('a')
      rescue Capybara::ElementNotFound
        puts "NO, this is a link."
        return false
      end
    end

    def scrape
      visit('http://www.36thdistrictcourt.org/bsi_docdisplay/Default.aspx')
      # puts page.body
      fill_in 'txtFRDktDate', with: '1/22/2016'
      fill_in 'txtTODktDate', with: '1/22/2016'
      select('07:00 AM', :from => 'lstFRDktTime')
      select('09:00 AM', :from => 'lstTODktTime')
      click_button 'Display Court Schedule'
      sleep 10
      page.should have_content('The Court Schedule selection returned')

      # puts page.body

      # Get the rows and drop the headers
      rows = page.all('table#gvDocket tr')

      rows.each do |row|
        # Skip the pager
        if row[:class] && row[:class].include?('mypager')
          next
        end

        # Skip the header
        if row.text.include? 'Judge/Mag/PO/Courtrm'
          next
        end

        tds = row.all('td')
        data = {
          judge: tds[0].text.strip,
          date: tds[1].text.strip,
          time: tds[2].text.strip,
          case_or_ticket: tds[3].text.strip,
          case_link: tds[3].find('a')['href'],
          name: tds[4].text.strip,
          action: tds[5].text.strip,
          court: tds[6].text.strip
        }

        query = %Q|insert into court (judge, date, time, case_or_ticket, case_link, name, action, court) values ('%{judge}', '%{date}', '%{time}', '%{case_or_ticket}', '%{case_link}', '%{name}', '%{action}', '%{court}')| % data

        # print query
        # puts row.text
      end

      # Go to the next page
      pager = page.all('tr.mypager').first.find('table tbody')
      pages = pager.all('td')
      click_next_link = false
      pages.each do |page_num|
        if click_next_link
          puts "clicking " + page_num.find('a').text
          click_link page_num.find('a')
          sleep 10
          puts page.body
          break
        end

        click_next_link = is_current_page(page_num)
      end
    end
  end
end

t = MyCapybaraScraper::Scrape.new
t.scrape
