# frozen_string_literal: true

require 'csv'
require 'write_xlsx'

class CsvToExcelConverter
  def convert(file_path)
    workbook = WriteXLSX.new(file_path.sub('.csv', '.xlsx'))
    worksheet1 = workbook.add_worksheet('Data')
    worksheet2 = workbook.add_worksheet('Images')

    # URL用のフォーマット（ハイパーリンク）
    url_format = workbook.add_format(color: 'blue', underline: 1)

    # csv_data = CSV.read(file_path, headers: true, encoding: 'Shift_JIS')
    csv_data = CSV.read(file_path, headers: true, encoding: 'Shift_JIS:UTF-8', invalid: :replace)

    headers = %w[チェック 商品名 落札価格 送料 合計 入札数 URL]
    worksheet1.write_row(0, 0, headers)

    current_directory = File.dirname(__FILE__)
    csv_data.each_with_index do |row, index|
      worksheet1.write(index + 1, 0, '☐') # チェックボックスとしての記号を追加
      row.each_with_index do |(header, cell), cell_idx|
        # ヘッダーを1つシフトして、チェックボックス用のスペースを作る
        adjusted_idx = cell_idx + 1

        if header == 'URL' && cell
          worksheet1.write(index + 1, adjusted_idx, cell, url_format)
        elsif header == 'image_path' && cell
          absolute_image_path = File.join(current_directory, cell)
          if File.exist?(absolute_image_path)
            worksheet2.insert_image(index, 0, absolute_image_path, cell_idx * 30, index * 150, 0.5, 0.5)
          else
            puts "画像が見つかりません: #{absolute_image_path}"
          end
        else
          worksheet1.write(index + 1, adjusted_idx, cell)
        end
      end
    end
    workbook.close
  end
end
