#!/usr/bin/env ruby
require 'erb'
require 'pathname'

home_dir = File.expand_path('../../', __FILE__)
ppt_dir = home_dir + '/_ppt/'
html_dir = home_dir + '/assets/ppt/'
template_file = home_dir + '/_layouts/ppt.html'

files = `ls #{ppt_dir}`.split
p files
files.each do |file|
  template = File.read (template_file )
  mdfile = File.read (ppt_dir + file )
  File.open(html_dir + file + '.html', 'w+') do |f|
    f.write(ERB.new(template.gsub(/MARKDOWN_REPLACER/, mdfile)).result(binding))
    f.close
  end
end
