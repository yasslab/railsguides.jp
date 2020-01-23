require 'uri'

# cf: https://gist.github.com/hanachin/9968957
RSpec::Matchers.define :be_dead_fragment do |page|
  # define_method :id_from_link do |link|
  #   _, fragment = link[:href].split("#", 2)
  #   id = URI.unescape(fragment)
  # end

  # define_method :file_from_link do |link|
  #   file, _ = link[:href].split("#", 2)
  #   file
  # end

  match do |link|
    @file, @fragment = link[:href].split("#", 2)
    @id = URI.unescape(@fragment)
    begin
      !page.find_by_id(@id)
    rescue => e
      raise if !e.instance_of?(Capybara::ElementNotFound)

      true
    end
  end

  failure_message_when_negated do |link|
    if !@file.empty?
      "Link(id: #{@id}, text: #{link.text}, fragment: #{@fragment}, file: #{@file}) is dead fragment"
    else
      "Link(id: #{@id}, text: #{link.text}, fragment: #{@fragment}) is dead fragment"
    end
  end

  failure_message do |link|
    if !@file.empty?
      "Link(id: #{@id}, text: #{link.text}, fragment: #{@fragment}, file: #{@file}) is not dead fragment"
    else
      "Link(id: #{@id}, text: #{link.text}, fragment: #{@fragment}) is not dead fragment"
    end
  end
end

RSpec::Matchers.define :be_dead_link do |status_code|
  match do |link|
    @link = link
    status_code != 200
  end

  failure_message_when_negated do |link|
    "Link(link: #{@link[:href]}) is dead link"
  end

  failure_message do |link|
    "Link(link: #{@link[:href]}) is not dead link"
  end
end
