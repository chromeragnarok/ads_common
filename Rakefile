#!/usr/bin/ruby
#
# Authors:: api.dklimkin@gmail.com (Danial Klimkin)
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
# Rakefile for the ads_common package.
require 'rake/testtask'
require 'rdoc/task'

files = FileList['lib/**/*', 'Rakefile'].to_a
docs = ['README', 'COPYING', 'ChangeLog']

desc 'Default target - build'
task :default => [:package]

# Create a task to build the RDOC documentation tree.
RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title = "%s -- Common code for Google Ads APIs" % GEM_NAME
  rdoc.main = 'README'
  rdoc.rdoc_files.include(docs)
  rdoc.rdoc_files.include(files)
end

# Create a task to perform the unit testing.
Rake::TestTask.new do |t|
  t.test_files = tests
end
