require 'Twitter'
require 'sequel'
require 'envyable'
Envyable.load('./config/env.yml')

DB = Sequel.connect(ENV['DATABASE_URL'])
DB.create_table? :twitter do
  primary_key :id
  integer :mention_id
  string :the_tweeter
  string :status
end

MENTIONS_DATASET = DB[:twitter]


def get_mention_and_fetch_user_friends
  ids_from_database_array = read_database_for_ids

  if ids_from_database_array.empty?
    mentions_array_from_timeline = fetch_mentions_from_twitter(count: 100, include_entites: false)
    iterate_over_mentions(mentions_array_from_timeline)
  else
    since_id = ids_from_database_array.last

    mentions_array_from_timeline = get_mentions_with_params(since_id)
    iterate_over_mentions(mentions_array_from_timeline)
  end
end

private

def call_twitter_api
  Twitter::REST::Client.new do |config|
    config.consumer_key = ENV['CONSUMER_KEY']
    config.consumer_secret = ENV['CONSUMER_SECRET']
    config.access_token = ENV['ACCESS_TOKEN']
    config.access_token_secret = ENV['ACCESS_TOKEN_SECRET']
  end
end

def iterate_over_mentions(mentions_array_from_timeline)
  mentions_array_from_timeline.each do |mention|
    the_tweeter = mention.user.screen_name

    format_mention = mention.text.downcase
    required_call = 'find me a val'
    mention_text = format_mention[required_call]

    create_or_insert_to_database(mention.id, the_tweeter)

    if mention_text == required_call
			the_tweeter_friends = @client.friend_ids(the_tweeter).to_a

	    random_valentine_id = the_tweeter_friends.sample

	    chosen_valentine = @client.user(random_valentine_id).screen_name

			#post_tweet(the_tweeter, chosen_valentine, mention.id)
		end
  end
end

def read_database_for_ids
  extracted_mention_ids_array = []

  MENTIONS_DATASET.each do |hash|
    extracted_mention_ids_array << hash[:mention_id]
  end

  extracted_mention_ids_array.sort
end

def create_or_insert_to_database(mention_id, mention_tweeter)
  status = "pending"

  MENTIONS_DATASET.insert(:mention_id => mention_id, :the_tweeter => mention_tweeter, :status => status)
end

def get_mentions_with_params(since_id)
  fetch_mentions_from_twitter(count: 100, include_entites: false, since_id: since_id)
end

def fetch_mentions_from_twitter(**args)
  @client = call_twitter_api
  @client.mentions_timeline(args)
end

def post_tweet(the_tweeter, valentine, mention_id)
  client.update("@#{the_tweeter} Your valentine is: @#{valentine} #ValentineBot", in_reply_to_status_id: mention_id)
end

get_mention_and_fetch_user_friends
