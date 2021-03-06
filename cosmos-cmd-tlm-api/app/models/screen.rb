# encoding: ascii-8bit

# Copyright 2021 Ball Aerospace & Technologies Corp.
# All Rights Reserved.
#
# This program is free software; you can modify and/or redistribute it
# under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation; version 3 with
# attribution addendums as found in the LICENSE.txt
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# This program may also be used under the terms of a commercial or
# enterprise edition license of COSMOS if purchased from the
# copyright holder

require 'cosmos/utilities/s3'

class Screen
  DEFAULT_BUCKET_NAME = 'config'

  def self.all(scope, target)
    rubys3_client = Aws::S3::Client.new
    resp = rubys3_client.list_objects_v2(bucket: DEFAULT_BUCKET_NAME)
    result = []
    contents = resp.to_h[:contents]
    if contents
      contents.each do |object|
        next unless object[:key].include?("#{scope}/targets/#{target}/screens/")
        filename = object[:key].split('/')[-1]
        next unless filename.include?(".txt")
        next if filename[0] == '_' # underscore filenames are partials
        result << File.basename(filename, ".txt").upcase
      end
    end
    result.sort
  end

  def self.find(scope, target, screen)
    rubys3_client = Aws::S3::Client.new
    resp = rubys3_client.get_object(bucket: DEFAULT_BUCKET_NAME, key: "#{scope}/targets/#{target}/screens/#{screen}.txt")
    @scope = scope
    @target = target
    file = resp.body.read
    # Remove all the commented out lines to prevent ERB from running
    file.gsub!(/^\s*#.*\n/,'')
    ERB.new(file).result(binding)
  end

  # Called by the ERB template to render a partial
  def self.render(template_name, options = {})
    raise Error.new(self, "Partial name '#{template_name}' must begin with an underscore.") if File.basename(template_name)[0] != '_'
    b = binding
    if options[:locals]
      options[:locals].each {|key, value| b.local_variable_set(key, value) }
    end
    rubys3_client = Aws::S3::Client.new
    resp = rubys3_client.get_object(bucket: DEFAULT_BUCKET_NAME, key: "#{@scope}/targets/#{@target}/screens/#{template_name}")
    ERB.new(resp.body.read).result(b)
  end
end
