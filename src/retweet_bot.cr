require "dotenv"
require "twitter-crystal"
require "./config"
Dotenv.load ".env"

class RetweetBot
  VERSION = "0.1.0"

  @api_client : Twitter::REST::Client?
  @stream_client : Twitter::Streaming::Client?
  @follow_ids : String?
  @rules : Hash(String, Regex)?

  def api_client
    @api_client ||= Twitter::REST::Client.new(
      ENV["API_KEY"],
      ENV["API_SECRET"],
      ENV["ACCESS_TOKEN"],
      ENV["ACCESS_SECRET"]
    )
  end

  def stream_client
    @stream_client ||= Twitter::Streaming::Client.new(
      ENV["API_KEY"],
      ENV["API_SECRET"],
      ENV["ACCESS_TOKEN"],
      ENV["ACCESS_SECRET"]
    )
  end

  def rules
    @rules ||= Config.from_yaml(File.new("config.yml")).rules.to_h { |r| {r.name, /#{r.text}/} }
  end

  def names
    rules.keys
  end

  def follow_ids
    @follow_ids ||= names.map { |n| api_client.user(n).id }.join(',')
  end

  def log(s)
    puts "#{Time.local} #{s}"
  end

  def log(v, s)
    log("#{v} | #{s}")
  end

  def start
    log "Start tracking tweets from #{names.map { |n| '@' + n }.join(", ")}."

    stream_client.filter({"follow" => follow_ids}) do |tweet|
      if tweet.is_a?(Twitter::Tweet) && !tweet.retweeted_status && (name = tweet.user.try &.screen_name)
        if (regex = rules[name]?) && tweet.text =~ regex
          api_client.retweet(tweet)
          log "Retweeted", "@#{name}: #{tweet.text}"
        end
      end
    end
  end
end

RetweetBot.new.start
