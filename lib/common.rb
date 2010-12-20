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

module Takibi
  module ClassAttribute
    # class instance variable setter/getter
    def civar attribute
      instance_eval %{
        def #{attribute} arg = nil, &block
          var = "@#{attribute}"
          if arg then
            instance_variable_set var, arg
          elsif instance_variable_defined?(var) and
            value = instance_variable_get(var) then
            value
          else
            block.call
          end
        end
      }
    end
  end
end

