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
    attr_reader :data_pathname

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

      saved_mask = File.umask(0o0002)
      File.open(@data_pathname, 'w') do |file|
        file.write data.to_yaml
      end
    rescue StandardError => e
      File.umask(saved_mask)
      raise
    end

    def load
      raise 'Failed to find a valid data pathname!!!' if @data_pathname.nil?

      if File.exist?(@data_pathname)
        data = YAML.safe_load(File.read(@data_pathname), [Symbol])
        if data.key?('isondisk')
          data = convert(data)
          save data
        end
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

    def convert(old)
      nh = {}
      nh[:created] = '¿Quién sabe?'
      nh[:converted] = Time.now.to_s
      old.each do |k,v|
        next if k == 'isondisk'
        next if k == 'puppet.run.failed' # orphaned alert
        next unless v.is_a?(Hash)
        next unless v.key?('count') && v.key?('throttled') && v.key?('last')

        nh[k] = {}
        nh[k][:count] = v['count']
        nh[k][:last] = v['last']
        nh[k][:throttled] = v['throttled']
      end
      nh
    end

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
