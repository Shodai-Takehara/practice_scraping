# frozen_string_literal: true

require_relative 'csv_to_excel_converter'
require 'selenium-webdriver'
require 'csv'
require 'open-uri'

class YahooAuctionScraper
  BASE_URL = 'https://auctions.yahoo.co.jp/search/advanced?auccat=0'
  SLEEP_TIME = 3
  TIMEOUT = 5

  attr_reader :csv_file

  def initialize
    @today = Time.now.strftime('%Y%m%d')
    @csv_file = "#{@today}_yahoo_auction_results.csv"
    @images_dir = "#{@today}_downloaded_images"
    FileUtils.mkdir_p(@images_dir) unless Dir.exist?(@images_dir)
    @driver = initialize_browser
  end

  def scrape(items_to_search)
    CSV.open(@csv_file, 'w', encoding: 'Shift_JIS') do |csv|
      csv << %w[商品名 価格 送料 合計価格 残り時間 URL image_path]
      items_to_search.each do |word, min_max_price|
        search_item(@driver, word, min_max_price[0], min_max_price[1])
        extract_data_and_write(csv)
      end
    end
    @driver.quit
    # @csv_file を返す
    @csv_file
  end

  private

  def initialize_browser
    Selenium::WebDriver.for :chrome
  end

  # ヤフオク検索
  def search_item(driver, word, min_price, max_price)
    driver.get(BASE_URL)
    driver.find_element(:xpath, '//input[@placeholder="すべて含む"]').send_keys(word)
    driver.find_element(:xpath, '//input[@name="aucminprice"]').send_keys(min_price)
    driver.find_element(:xpath, '//input[@name="aucmaxprice"]').send_keys(max_price)
    driver.find_element(:id, 'btn').click
    sleep(SLEEP_TIME)
  end

  # 商品情報の取得
  def fetch_product_info(product)
    title_element = product.find_element(:css, '.Product__titleLink')
    title = title_element.text
    url = title_element.attribute('href')
    price = product.find_element(:css, '.Product__priceValue').text.delete(',円').to_i
    postage = product.find_element(:css, '.Product__postage').text
    time_left_element = product.find_element(:css, '.Product__time')
    time_left = time_left_element.text
    image_element = product.find_element(:css, '.Product__imageData')
    image_url = image_element.attribute('src')

    [title, price, postage, time_left, url, image_url]
  end

  # 画像をダウンロードしてローカルに保存
  def download_image(title, image_url)
    image_filename = File.join(@images_dir, safe_filename(title))
    begin
      IO.copy_stream(URI.open(image_url), image_filename)
    rescue StandardError => e
      puts "Error occurred: #{e.message}"
    end
    image_filename
  end

  def safe_filename(title)
    # 特定の文字を取り除き、スペースをアンダースコアに置換
    "#{title.gsub(%r{[/?<>\\:*|"]}, '').gsub(' ', '_')[0, 50]}.png"
  end

  # 送料の整形
  def format_postage(postage)
    case postage
    when '送料未定'
      '未定'
    when '送料無料'
      '無料'
    else
      postage.delete(' ＋送料')
    end
  end

  # 合計価格の計算
  def calculate_total_price(price, new_postage, postage)
    if postage.include?('＋送料')
      price + new_postage.delete(',円').to_i
    elsif postage == '送料無料'
      price.delete(',円').to_i
    else
      ''
    end
  end

  # メインの処理
  def extract_data_and_write(csv)
    Selenium::WebDriver::Wait.new(timeout: TIMEOUT)

    continue_scraping = true

    while continue_scraping
      products = @driver.find_elements(:css, '.Products__items > li.Product')
      products.each do |product|
        title, price, postage, time_left, url, image_url = fetch_product_info(product)
        new_postage = format_postage(postage)
        total_price = calculate_total_price(price, new_postage, postage)

        next unless time_left.include?('時間')

        hours_left = time_left.gsub('時間', '').strip.to_i
        next if hours_left > 12

        image_filename = download_image(title, image_url)
        csv << [title, price, new_postage, total_price, hours_left, url, image_filename]
      end

      # ページ内の商品数が50未満の場合はフラグをfalseにしてループを終了する
      if products.size < 50
        continue_scraping = false
      else
        # 次のページへ移動
        pagination = @driver.find_elements(:css, '.Pager__lists > li.Pager__list')
        next_button = pagination.last.find_element(:css, '.Pager__link')
        next_button.click
      end
      sleep(SLEEP_TIME)
    end
  end
end

scraper = YahooAuctionScraper.new
items_to_search = {
  'RRL Tシャツ' => [1000, 2000],
  'ラルフローレン アロハシャツ' => [1000, 10_000]
}
scraper.scrape(items_to_search)

converter = CsvToExcelConverter.new
converter.convert(scraper.csv_file)
