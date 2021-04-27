require 'logger'
require 'sinatra'

configure do
    $stdout.sync = true
    logger = Logger.new(STDOUT)
    logger.level = Logger::DEBUG

    set :logger, logger
end

post "/" do
    request.body.rewind
    data = request.body.read
    settings.logger.debug ("--- START POST ---")
    settings.logger.debug(data)
    settings.logger.debug ("--- END POST ---")
    return data
end