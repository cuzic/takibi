require 'rubygems'
require 'log4r'

def create_logger
    formatter = Log4r::PatternFormatter.new(
        :pattern => "%d [%l] %M", :date_pattern => "%H:%M:%S")
        outputter = Log4r::StderrOutputter.new("", :formatter => formatter)
        logger = Log4r::Logger.new($0)
        logger.add(outputter)
        logger.level = Log4r::DEBUG
        return logger
end
