#!/usr/bin/ruby
#
# Author:: api.dklimkin@gmail.com (Danial Klimkin)
#
# Copyright:: Copyright 2011, Google Inc. All Rights Reserved.
#
# License:: Licensed under the Apache License, Version 2.0 (the "License");
#           you may not use this file except in compliance with the License.
#           You may obtain a copy of the License at
#
#           http://www.apache.org/licenses/LICENSE-2.0
#
#           Unless required by applicable law or agreed to in writing, software
#           distributed under the License is distributed on an "AS IS" BASIS,
#           WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
#           implied.
#           See the License for the specific language governing permissions and
#           limitations under the License.
#
# Code template generator base class

require 'savon'
require 'erb'

module AdsCommon
  module Build
    class SavonAbstractGenerator
      def initialize(args)
        if self.class() == AdsCommon::Build::SavonAbstractGenerator
          raise NoMethodError, "Tried to instantiate an abstract class"
        end
        @require_path = args[:require_path]
        @service_name = args[:service_name]
        @module_name  = args[:module_name]
        @namespace = args[:namespace]
        @logger = args[:logger]
        @generator_stamp = "Code generated by AdsCommon library %s on %s." %
            [AdsCommon::ApiConfig::ADS_COMMON_VERSION,
             Time.now.strftime("%Y-%m-%d %H:%M:%S")]
        prepare_modules_string()
      end

      def generate_code()
        code = ERB.new(get_code_template(), 0, '%<>')
        return remove_lines_with_blanks_only(code.result(binding))
      end

      def get_code_template()
        raise NotImplementedError
      end

      def prepare_modules_string()
        modules_count = @module_name.scan(/::/).length
        @modules_open_string = 'module ' + @module_name.gsub(/::/, '; module ')
        @modules_close_string = 'end; ' * modules_count
        @modules_close_string += 'end'
      end

      def remove_lines_with_blanks_only(text)
        return text.gsub(/\n\ +$/, '')
      end
    end
  end
end
