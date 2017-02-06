#!/usr/bin/env ruby
t = Time.now.to_f
require 'open-uri'
require 'nokogiri'
require 'csv'
require 'benchmark'

# url to the product page, csv-file to write into
def parse_multiproduct(url_multiproduct, csv_file)
  # dunno how to avoid ABCsize warning
  puts 'parsing multiproduct '
  row = []
  page = Nokogiri::HTML(open(url_multiproduct))
  image = page.at_css('img#bigpic').attribute('src')
  # remove unneeded span with producer info
  page.at_xpath("//div[@class='product-name']/h1/span").remove
  name = page.at_xpath("//div[@class='product-name']/h1").content.strip
  page.xpath("//ul[@class='attribute_labels_lists']")
      .map do |node|
        weight = node.at_css('span.attribute_name').text.strip
        row[0] = "#{name} - #{weight}"
        # exact point to have correct order in case it works async
        price = node.at_css('span.attribute_price').text.strip
        row[1] = price.to_s
        row[2] = image.to_s
        csv_file << row # ["#{name} - #{weight}", price, image]
      end
end

# Nokogiri document object, csv-file to write into
def parse_category_page(category_page, csv_file)
  # choose block without ads to iterate
  category_page.xpath("//div[@class='productlist']//a[@class='product-name']")
               .map do |node|
                 parse_multiproduct(node.attribute('href'), csv_file)
               end
end

url_category = ARGV[0]
file = ARGV[1]

file += '.csv' unless file.include?('.csv')
csv_file = CSV.open(file, 'w')
page_counter = 1

loop do
  puts 'parsing category page: '
  puts "#{url_category}?p=#{page_counter}"
  category_page = Nokogiri::HTML(open("#{url_category}?p=#{page_counter}"))
  parse_category_page(category_page, csv_file)
  # break if there is no next page button
  break unless category_page.at_xpath"//li[@class='pagination_next']/a"
  page_counter += 1
end

csv_file.close
puts "results saved to #{file}"
puts "finished in #{(Time.now.to_f - t).round(1)} seconds"
