require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/cross_origin'
require 'sinatra/json'
require 'json'

require 'natto'
require 'moji'

configure :production do
  require 'newrelic_rpm'
end

configure do
  enable :cross_origin
end

last_request_time = ""
request_counter = 0

get '/' do
  erb :index
end

post '/hiragana', provides: :json do
  body = JSON.parse(request.body.read) rescue ""
  if body == ""
    status 400
  else
    request_id = ""
    if body["request_id"].nil?
      t = Time.now
      if t.to_i == last_request_time
        request_counter += 1
      else
        request_counter = 0
        last_request_time = t.to_i
      end
      request_id = "#{t.to_i}\t#{request_counter}"
    else
      request_id = body["request_id"]
    end

    sentence = ""
    normalized = false
    if body["normalize"] == "true"
      sentence = normalize_neologd(body["sentence"])
      normalized = true
    else
      sentence = body["sentence"]
      normalized = false
    end

    converted = parse(sentence).join(" ")
    if body["output_type"] == 'hiragana'
      converted = converted.tr('ァ-ン','ぁ-ん')
    end

    data = { request_id: request_id, converted: converted, normalized: normalized }
    json data
  end
end

helpers do
  if ENV["MECAB_API_DICDIR"]
    $nm = Natto::MeCab.new(dicdir: ENV["MECAB_API_DICDIR"])
  else
    $nm = Natto::MeCab.new
  end

  def parse(text)
    data = []
    $nm.parse(text) do |n|
      data.push(n.feature.split(",")[7])
    end
    data[0...-1]
  end

  # https://github.com/neologd/mecab-ipadic-neologd/wiki/Regexp.ja
  # written by kimoto (https://github.com/kimoto)
  def normalize_neologd(norm)
    puts "input: " + norm
    norm.tr!("０-９Ａ-Ｚａ-ｚ", "0-9A-Za-z")
    norm = Moji.han_to_zen(norm, Moji::HAN_KATA)
    hypon_reg = /(?:˗|֊|‐|‑|‒|–|⁃|⁻|₋|−)/
    norm.gsub!(hypon_reg, "-")
    choon_reg = /(?:﹣|－|ｰ|—|―|─|━)/
    norm.gsub!(choon_reg, "ー")
    chil_reg = /(?:~|∼|∾|〜|〰|～)/
    norm.gsub!(chil_reg, '')
    norm.gsub!(/[ー]+/, "ー")
    norm.tr!(%q{!"#$%&'()*+,-.\/:;<=>?@[\]^_`{|}~｡､･｢｣"}, %q{！”＃＄％＆’（）＊＋，−．／：；＜＝＞？＠［￥］＾＿｀｛｜｝〜。、・「」})
    norm.gsub!(/　/, " ")
    norm.gsub!(/ {1,}/, " ")
    norm.gsub!(/^[ ]+(.+?)$/, "\\1")
    norm.gsub!(/^(.+?)[ ]+$/, "\\1")
    while norm =~ %r{([\p{InCJKUnifiedIdeographs}\p{InHiragana}\p{InKatakana}\p{InHalfwidthAndFullwidthForms}\p{InCJKSymbolsAndPunctuation}]+)[ ]{1}([\p{InCJKUnifiedIdeographs}\p{InHiragana}\p{InKatakana}\p{InHalfwidthAndFullwidthForms}\p{InCJKSymbolsAndPunctuation}]+)}
      norm.gsub!( %r{([\p{InCJKUnifiedIdeographs}\p{InHiragana}\p{InKatakana}\p{InHalfwidthAndFullwidthForms}\p{InCJKSymbolsAndPunctuation}]+)[ ]{1}([\p{InCJKUnifiedIdeographs}\p{InHiragana}\p{InKatakana}\p{InHalfwidthAndFullwidthForms}\p{InCJKSymbolsAndPunctuation}]+)}, "\\1\\2")
    end
    while norm =~ %r{([\p{InBasicLatin}]+)[ ]{1}([\p{InCJKUnifiedIdeographs}\p{InHiragana}\p{InKatakana}\p{InHalfwidthAndFullwidthForms}\p{InCJKSymbolsAndPunctuation}]+)}
      norm.gsub!(%r{([\p{InBasicLatin}]+)[ ]{1}([\p{InCJKUnifiedIdeographs}\p{InHiragana}\p{InKatakana}\p{InHalfwidthAndFullwidthForms}\p{InCJKSymbolsAndPunctuation}]+)}, "\\1\\2")
    end
    while norm =~ %r{([\p{InCJKUnifiedIdeographs}\p{InHiragana}\p{InKatakana}\p{InHalfwidthAndFullwidthForms}\p{InCJKSymbolsAndPunctuation}]+)[ ]{1}([\p{InBasicLatin}]+)}
      norm.gsub!(%r{([\p{InCJKUnifiedIdeographs}\p{InHiragana}\p{InKatakana}\p{InHalfwidthAndFullwidthForms}\p{InCJKSymbolsAndPunctuation}]+)[ ]{1}([\p{InBasicLatin}]+)}, "\\1\\2")
    end
    norm.tr!(
      %q{！”＃＄％＆’（）＊＋，−．／：；＜＞？＠［￥］＾＿｀｛｜｝〜},
      %q{!"#$%&'()*+,-.\/:;<>?@[\]^_`{|}~}
    )
    puts "output: " + norm
    norm
  end
end
