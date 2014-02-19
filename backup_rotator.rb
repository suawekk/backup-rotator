#!/usr/bin/env ruby
require './job_server.rb'

module BackupRotator


    class BackupRotator
        def initialize
            js = JobServer.new(8)
        end


    end
    BackupRotator.new
end

