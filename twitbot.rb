require 'Twitter'
require 'csv'
require 'sequel'
require 'envyable'
Envyable.load('./config/env.yml')

FILE_NAME = "mentions.csv"

def get_mention_and_fetch_user_friends
	ids_from_csv_array = read_csv_for_ids

	if ids_from_csv_array.empty?
		mentions_array_from_timeline = fetch_mentions_from_twitter(count: 100, include_entites: false)
		iterate_over_mentions(mentions_array_from_timeline)
	else
		ids_from_csv_array.pop
		since_id = ids_from_csv_array.last.to_i

		mentions_array_from_timeline = get_mentions_with_params(since_id)
		iterate_over_mentions(mentions_array_from_timeline)
	end
end


private

def call_twitter_api
	Twitter::REST::Client.new do |config|
	  config.consumer_key        = ENV['CONSUMER_KEY']
	  config.consumer_secret     = ENV['CONSUMER_SECRET']
	  config.access_token        = ENV['ACCESS_TOKEN']
	  config.access_token_secret = ENV['ACCESS_TOKEN_SECRET']
	end
end

def iterate_over_mentions(mentions_array_from_timeline)
	mentions_array_from_timeline.each do |mention|
		the_tweeter = mention.user.screen_name

		format_mention = mention.text.downcase
		required_call = "find me a val"
		mention_text = format_mention[required_call]

		create_or_append_to_csv(mention.id, the_tweeter)

		if mention_text == required_call
			the_tweeter_friends = @client.friend_ids(the_tweeter).to_a

			random_valentine_id = the_tweeter_friends.sample

			chosen_valentine = @client.user(random_valentine_id).screen_name

			#post_tweet(the_tweeter, chosen_valentine, mention.id)
		end
	end		
end

def read_csv_for_ids
	mentions_array = []
	extracted_mention_ids_array = []

	if File.file?(FILE_NAME)
		CSV.foreach(FILE_NAME) do |line|
			mentions_array << line
		end
	end

	mentions_array.map { |e| extracted_mention_ids_array << e[0]  }
	
	extracted_mention_ids_array.sort
end

def get_mentions_with_params(since_id)
	fetch_mentions_from_twitter(count: 100, include_entites: false, since_id: since_id)
end


def fetch_mentions_from_twitter(**args)
	@client = call_twitter_api
	@client.mentions_timeline(args)
end

def create_or_append_to_csv(mention_id, mention_tweeter)
	headers = ["mention_ids", "the_tweeter"]

	CSV.open(FILE_NAME, "a+") do |csv|
		if csv.count.eql? 0
			csv << headers
		end
		
		csv << [mention_id, mention_tweeter]
	end
end

def post_tweet(the_tweeter, valentine, mention_id)
	client.update("@#{the_tweeter} Your valentine is: @#{valentine} #ValentineBot", in_reply_to_status_id: mention_id)
end

get_mention_and_fetch_user_friends