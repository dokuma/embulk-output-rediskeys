module Embulk
  module Output

    class Redis < OutputPlugin
      require 'redis'
      require 'json'
      require 'set'

      Plugin.register_output("rediskeys", self)

      def self.transaction(config, schema, count, &control)
        # configuration code:
        task = {
          'host' => config.param('host', :string, :default => 'localhost'),
          'port' => config.param('port', :integer, :default => 6379),
          'db' => config.param('db', :integer, :default => 0),
          'key_prefix' => config.param('key_prefix', :string, :default => ''),
          'encode' => config.param('encode', :string, :default => 'json')
        }

        # resumable output:
        # resume(task, schema, count, &control)

        # non-resumable output:
        task_reports = yield(task)
        puts "Redis output finished. Commit reports = #{task_reports.to_json}"

        next_config_diff = {}
        return next_config_diff
      end

      #def self.resume(task, schema, count, &control)
      #  task_reports = yield(task)
      #
      #  next_config_diff = {}
      #  return next_config_diff
      #end

      def init
        # initialization code:
        puts "Redis output thread #{index}..."
        super
        @rows = 0
        @processed_keys = [].to_set
        @unique_keys = [].to_set
        @redis = ::Redis.new(:host => task['host'], :port => task['port'], :db => task['db'])
      end

      def close
      end

      def add(page)
        # output code:
        page.each do |records|
          puts "Schema: #{schema.names}"
          # puts "Record: #{records}"
          records.each do |record|
            hash = JSON.parse(record)

            k = nil
            v = hash.select{|key,v|
              k = key
              key.match(/^#{task['key_prefix']}/)
            }

            puts "KEY: #{k}"

            @processed_keys << k
            unless @unique_keys.include? k
              case task['encode']
              when 'json'
                v = v[k].to_json
                @redis.set(k, v)
              when 'hash'
                v = v[k]
                puts "VALUE: #{v}"
                puts "FLATTEN: #{v.to_a.flatten}"
                @redis.hmset(k, v.to_a.flatten)
              end
              @unique_keys << k
            else
              puts "Warning: #{k} is already exists"
            end
            @rows += 1  # inrement anyway
          end
        end
      end

      def finish
      end

      def abort
      end

      def commit
        task_report = {
          "rows" => @rows,
          "processed_keys" => @processed_keys.inspect,
          "unique_keys" => @unique_keys.inspect
        }
        return task_report
      end
    end

  end
end

