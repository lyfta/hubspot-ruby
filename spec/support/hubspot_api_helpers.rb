module HubspotApiHelpers
  def hubspot_api_url(path)
    URI.join(OldHubspot::Config.base_url, path)
  end
end

RSpec.configure do |c|
  c.include HubspotApiHelpers
end
