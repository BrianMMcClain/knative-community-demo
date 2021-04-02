require 'logger'
require 'cloud_events'
require 'httparty'
require 'optimist'
require 'json'

$stdout.sync = true
@logger = Logger.new(STDOUT)

# DEBUG: Show args and environment variables
@logger.level = Logger::DEBUG
@logger.debug("ARGS: #{ARGV}")

ENV.keys.each do |k|
    @logger.debug("#{k}: #{ENV[k]}")
end

# Retrieves all comments for a given issue
def getComments(owner, repo, issue)
    @logger.debug("https://api.github.com/repos/#{owner}/#{repo}/issues/#{issue}/comments")
    res = HTTParty.get("https://api.github.com/repos/#{owner}/#{repo}/issues/#{issue}/comments", :headers => {
        "Accept" => "application/vnd.github.v3+json"
    })
    return JSON.parse(res.body)
end

# Sends a CloudEvent-formatted HTTP POST to the provided sink
def sendEvent(comment, owner, repo, issue, sink)
    @logger.info("Sending info to #{sink}")
    data = { 
        message: comment["body"],
        user: comment["user"]["login"],
        timestamp: comment["created_at"],
        url: comment["html_url"]
    }
    event = CloudEvents::Event.create spec_version: "1.0",
                                    id:           "#{comment['id']}",
                                    source:       "/#{owner}/#{repo}/#{issue}",
                                    type:         "com.github.brianmmcclain.github-issue-comment-source",
                                    data:         data

    cloud_events_http = CloudEvents::HttpBinding.default

    headers, body = cloud_events_http.encode_binary_content event

    @logger.debug(headers)
    @logger.debug(body)

    if not sink.nil?
        res = HTTParty.post(sink, :body => body, :headers => headers)
        @logger.debug(res)
    else
        @logger.debug("No sink, skipping")
    end
end

# Pulls the comments for the given GitHub issue and determins if 
# a new one has been made since the last time it was checked
def pollComments(owner, repo, issue, sink, lastID)
    newLastID = lastID
    comments = getComments(owner, repo, issue)
    comments.each do |c|
        if c["id"] > newLastID
            sendEvent(c, owner, repo, issue, sink)
            newLastID = c["id"]
        end
    end

    return newLastID
end

# Determine the comment ID to start with
def getLatestID(owner, repo, issue, fromBeginning)
    if fromBeginning
        return 0
    else
        i = getComments(owner, repo, issue)
        return i.last["id"].to_i
    end
end

# Parse CLI options
opts = Optimist::options do
    banner <<-EOS
Poll GitHub Issue Comments
Usage:
  ruby github-issue-comment-source.rb
EOS
    opt :interval, "Poll Frequency", 
        :default => 60,
        :type => :int
    opt :owner, "Repo owner",
        :required => true,
        :type => :string
    opt :repo, "Repo",
        :required => true,
        :type => :string
    opt :issue, "Issue Number",
        :required => true,
        :type => :string
    opt :fromBeginning, "Start from first comment",
        :default => false,
        :type => :flag
        
end
@logger.debug(opts)

# Determine if we should start with the latest comment or from the beginning
lastID = getLatestID(opts[:owner], opts[:repo], opts[:issue], opts[:fromBeginning])
@logger.debug("Last ID: #{lastID}")

# Determine if a sink has been provided
sink = nil
if ENV.has_key? "K_SINK"
    sink = ENV["K_SINK"]
end

# Check for new comments on the provided interval
while true do
    lastID = pollComments(opts[:owner], opts[:repo], opts[:issue], sink, lastID)
    @logger.debug("Last ID: #{lastID}")
    sleep opts[:interval]
end