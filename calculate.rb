require "uri"
require "net/http"
require "json"

# first input
puts "\n"
puts "Welcome to the Bitcoin fee estimator! "
puts "How fast should your transaction get the first confirmation on the Bitcoin blockchain? \n"
puts "
1 = Next block (~10 min)
2 = 30 minutes
3 = 60 minutes (cheapest option)
"

x = gets.chomp.to_i
puts "\n"

# get current fees from mempool.space and structure them by much it takes to be in block x
url = URI("https://mempool.space/api/v1/fees/recommended")

https = Net::HTTP.new(url.host, url.port)
https.use_ssl = true

request = Net::HTTP::Get.new(url)

response = https.request(request)
b = response.body

case x
when 1
    fast = eval(b)[:fastestFee]
    puts "You need to set #{fast} sat/vB as a fee"
when 2
    half = eval(b)[:halfHourFee]
    puts "You need to set #{half} sat/vB as a fee"
when 3
    hour = eval(b)[:hourFee]
    puts "You need to set #{hour} sat/vB as a fee"
end
puts "------------------------------------------------------"
puts "Now lets calculate the total fee for your transaction."
puts "Transaction type? (which adress format)\n"
puts "
1 = Segwit (newer)
2 = Legacy (older)
"
txtype = gets.chomp.to_i
puts "\n"

puts "Input count? (1 or 2)\n"
inputcount = gets.chomp.to_i
puts "Output count? (1 or 2)\n"
outputcount = gets.chomp.to_i


# transaction size based on estimated of https://www.buybitcoinworldwide.com/fee-calculator/
specificfee = if txtype == 2 && inputcount == 1 && outputcount == 1
                    192
                elsif txtype == 2 && inputcount == 2 && outputcount == 1
                    340
                elsif txtype == 2 && inputcount == 1 && outputcount == 2
                    226
                elsif txtype == 1 && inputcount == 1 && outputcount == 1
                    138
                elsif txtype == 1 && inputcount == 2 && outputcount == 1
                    231
                elsif txtype == 1 && inputcount == 1 && outputcount == 2
                    172
                end


# calculate size in satoshis
calcsize = specificfee.to_i * case x
when 1
    fast
when 2
    half
when 3
    hour
end

# get current btc price with API call from coindesk
url = URI("https://api.coindesk.com/v1/bpi/currentprice.json")

https = Net::HTTP.new(url.host, url.port)
https.use_ssl = true

request = Net::HTTP::Get.new(url)

response = https.request(request)
b = response.body
price = eval(b)[:bpi][:USD][:rate_float]

# calculate fiat transaction cost
usdsize = calcsize.to_f / 100000000 * price

# actual fee estimation output
puts "\n"
puts "Your estimated fee is #{calcsize} sats or $#{usdsize.round(2)}"