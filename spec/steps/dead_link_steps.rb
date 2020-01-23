step '表示されている内部リンクは、すべて有効である' do
  _, internal_links = all('a').partition {|link| link[:href].start_with?('http') || link[:href].start_with?('irc') }
  fragment_links, not_fragment_links = internal_links.partition {|link| link[:href] =~ /#/ }

  # ["#active-record-enums"], ["/asset_pipeline.html#css%E3%81%A8erb"]
  same_pages, other_pages = fragment_links.partition {|link| link[:href] =~ /\A#/ }
  same_pages.each do |link|
    expect(link).to_not be_dead_fragment(page)
  end

  other_pages.each do |link|
    file, _ = link[:href].split("#", 2)
    visit file
    expect(link).to_not be_dead_fragment(page)
  end

  not_fragment_links.each do |link|
    next if link[:href] == "/"
    visit(link[:href])
    expect(link).to_not be_dead_link(status_code)
  end
end
