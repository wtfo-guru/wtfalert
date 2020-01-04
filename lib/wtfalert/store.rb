# frozen_string_literal: true

require 'yaml'

#
# @module Wtfalert
#
module Wtfalert
  #
  # @class Store
  #
  class Store
    def initialize(store)
      @stores = {}
      @data_pathname = nil
      [store, ENV['HOME'], '/tmp'].each do |sd|
        spn = File.join(sd, 'alerts.yaml')
        @stores[spn] = check_store(sd, spn)
        if @stores[spn] == 'okay'
          @data_pathname = spn
          break
        end
      end
    end

    def save(data)
      raise 'Failed to find a valid data pathname!!!' if @data_pathname.nil?

      File.open(@data_pathname, 'w') do |file|
        file.write data.to_yaml
      end
    end

    def load
      raise 'Failed to find a valid data pathname!!!' if @data_pathname.nil?

      if File.exist?(@data_pathname)
        data = YAML.safe_load(File.read(@data_pathname), [Symbol])
      else
        data = {}
        data[:created] = Time.now.to_s
        save data
      end
      data
    end

    def lockname
      raise 'Failed to find a valid data pathname!!!' if @data_pathname.nil?

      return @lockname if @lockname

      base = File.basename(@data_pathname)
      @lockname = File.join(File.dirname(@data_pathname), ".#{base}.lock")
    end

    private

    def check_store(parent, fpn)
      return 'Directory not found!' unless File.directory?(parent)

      if File.exist?(fpn)
        if File.readable?(fpn)
          File.writable?(fpn) ? 'okay' : 'File not writable!'
        else
          'File not readable!'
        end
      elsif File.writable?(parent)
        'okay'
      else
        'Directory not writable!'
      end
    end
  end
end
