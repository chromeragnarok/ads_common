#!/usr/bin/ruby
#
# Authors:: api.sgomes@gmail.com (Sérgio Gomes)
#
# Copyright:: Copyright 2010, Google Inc. All Rights Reserved.
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
# Generic Api class, to be inherited from and extended by specific APIs.

require 'logger'

require 'ads_common/errors'
require 'ads_common/auth/base_handler'
require 'ads_common/auth/client_login_handler'
require 'ads_common/soap4r_headers/nested_header_handler'
require 'ads_common/soap4r_headers/single_header_handler'
require 'ads_common/soap4r_response_handler'
require 'ads_common/soap4r_logger'

module AdsCommon
  class Api

    # Methods that return the service configuration and the client library
    # configuration. They need to be redefined in subclasses.
    attr_reader :api_config, :config

    # Credential handler objects used for authentication
    attr_reader :credential_handler

    # The configuration for this Api object
    attr_reader :config

    # The logger for this Api object.
    attr_reader :logger

    # Constructor for Api.
    def initialize(provided_config = nil)
      load_config(provided_config)
      provided_logger = @config.read('library.logger')
      self.logger = (provided_logger.nil?) ?
          create_default_logger() : provided_logger
    end

    # Sets the logger to use.
    def logger=(logger)
      @logger = logger
      @config.set('library.logger', @logger)
    end

    # Obtain an API service, given a version and its name.
    #
    # Args:
    # - name: name for the intended service
    # - version: intended API version.
    #
    # Returns:
    # - the service wrapper for the intended service.
    #
    def service(name, version = nil)
      version = api_config.default_version if version == nil
      # Check if version exists
      if !api_config.versions.include?(version.to_sym)
        if version.is_a? Integer
          raise AdsCommon::Errors::Error, "Unknown version '#{version}'. " +
              "Please note that version numbers should be symbols; check the" +
              "Readme or the included examples for more information."
        else
          raise AdsCommon::Errors::Error, "Unknown version #{version}"
        end
      end
      version = version.to_sym
      name = name.to_sym
      environment = config.read('service.environment')
      # Check if the current environment supports the requested version
      if !api_config.environment_has_version(environment, version)
        raise AdsCommon::Errors::Error,
          "Environment #{environment} does not support version #{version}"
      end
      # Check if the specified version has the requested service
      if !api_config.version_has_service(version, name)
        raise AdsCommon::Errors::Error, "Version #{version} does not contain " +
          "service #{name}"
      end
      prepare_driver(version, name)
      return @wrappers[[version, name]]
    end

    # Retrieve the SOAP header handlers to plug into the drivers. Needs to
    # be implemented on the specific API, because of the different types of
    # SOAP headers (optional parameter specifying API version).
    #
    # Args:
    # - auth_handler: instance of an AdsCommon::Auth::BaseHandler subclass to
    #   handle authentication
    # - header_list: the list of headers to be handled
    # - version: intended API version
    # - wrapper: wrapper object for the service being handled
    #
    # Returns:
    # - a list of SOAP header handlers; one per provided header
    #
    def soap_header_handlers(auth_handler, header_list, version, wrapper = nil)
    end

    private

    # Auxiliary method to create an authentication handler. Needs to be
    # implemented on the specific API because of the different nesting models
    # used in different APIs and API versions.
    #
    # Args:
    # - version: intended API version
    # - environment: the current working environment (production, sandbox, etc.)
    #
    # Returns:
    # - auth handler
    #
    def create_auth_handler(version = nil, environment = nil)
    end

    # Handle loading of a single service.
    # Creates the driver, sets up handlers and logger, declares the appropriate
    # wrapper class and creates an instance of it.
    #
    # Args:
    # - version: intended API version. Must be an integer.
    # - service: name for the intended service
    #
    # Returns:
    # - the driver for the service
    # - the simplified wrapper generated for the driver
    #
    def prepare_driver(version, service)
      version = version.to_sym
      service = service.to_sym
      environment = config.read('service.environment')
      api_config.do_require(version, service)
      endpoint = api_config.endpoint(environment, version, service)
      # Set endpoint if not using the default
      if endpoint.nil? then
        driver = eval("#{api_config.interface_name(version, service)}.new")
      else
        endpoint_url = endpoint.to_s + service.to_s
        driver = eval("#{api_config.interface_name(version, service)}.new" +
                      "(\"#{endpoint_url}\")")
      end

      # Create an instance of the wrapper class for this service.
      wrapper_class = api_config.wrapper_name(version, service)
      wrapper = eval("#{wrapper_class}.new(driver, self)")

      auth_handler = create_auth_handler(version, environment)
      header_list =
          auth_handler.header_list(@credential_handler.credentials(version))

      soap_handlers = soap_header_handlers(auth_handler, header_list, version,
          wrapper)

      soap_handlers.each do |handler|
        driver.headerhandler << handler
      end

      # Add response handler to this driver for API unit usage processing.
      driver.callbackhandler = create_callback_handler
      # Plug the wiredump to our XML logger
      driver.wiredump_dev = AdsCommon::Soap4rLogger.new(@logger, Logger::DEBUG)
      driver.options['protocol.http.ssl_config.verify_mode'] = nil
      proxy = config.read('connection.proxy')
      if proxy
        driver.options['protocol.http.proxy'] = proxy
      end

      @drivers[[version, service]] = driver
      @wrappers[[version, service]] = wrapper
      return driver, wrapper
    end

    # Auxiliary method to create a default Logger.
    def create_default_logger()
      logger = Logger.new(STDOUT)
      logger.level = get_log_level_for_string(
          @config.read('library.log_level', Logger::INFO))
      return logger
    end

    # Helper method to load the default configuration file or a given config.
    def load_config(provided_config = nil)
      @config = (provided_config.nil?) ?
          AdsCommon::Config.new(
              File.join(ENV['HOME'], default_config_filename)) :
          AdsCommon::Config.new(provided_config)
    end

    # Gets the default config filename.
    def default_config_filename()
      return api_config.default_config_filename
    end

    # Converts log level string (from config) to Logger value.
    def get_log_level_for_string(log_level)
      result = log_level
      if log_level.is_a?(String)
        result = case log_level.upcase
          when 'FATAL' then Logger::FATAL
          when 'ERROR' then Logger:ERROR
          when 'WARN' then Logger::WARN
          when 'INFO' then Logger::INFO
          when 'DEBUG' then Logger::DEBUG
        end
      end
      return result
    end
  end
end
