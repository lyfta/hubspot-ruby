describe OldHubspot::Config do
  describe ".configure" do
    it "sets the hapikey config" do
      hapikey = "demo"

      config = OldHubspot::Config.configure(hapikey: hapikey)

      expect(config.hapikey).to eq(hapikey)
    end

    it "changes the base_url" do
      base_url = "https://api.hubapi.com/v2"

      config = OldHubspot::Config.configure(
        hapikey: "123abc",
        base_url: base_url
      )

      expect(config.base_url).to eq(base_url)
    end

    it "sets a default value for base_url" do
      config = OldHubspot::Config.configure(hapikey: "123abc")

      expect(config.base_url).to eq("https://api.hubapi.com")
    end

    it "sets a value for portal_id" do
      portal_id = "62515"

      config = OldHubspot::Config.configure(
        hapikey: "123abc",
        portal_id: portal_id
      )

      expect(config.portal_id).to eq(portal_id)
    end

    it "raises when an authentication approach is not provided" do
      expect {
        OldHubspot::Config.configure({})
      }.to raise_error(OldHubspot::ConfigurationError)
    end

    it "raises when two authentication approaches are provided" do
      expect {
        OldHubspot::Config.configure({
          hapikey: "123abc",
          access_token: "456def",
        })
      }.to raise_error(OldHubspot::ConfigurationError)
    end
  end

  describe ".reset!" do
    it "resets the config values" do
      OldHubspot::Config.configure(hapikey: "123abc", portal_id: "456def")

      OldHubspot::Config.reset!

      expect(OldHubspot::Config.hapikey).to be nil
      expect(OldHubspot::Config.portal_id).to be nil
    end
  end

  describe ".ensure!" do
    context "when a specified parameter is missing" do
      it "raises an error" do
        OldHubspot::Config.configure(hapikey: "123abc")

        expect {
          OldHubspot::Config.ensure!(:portal_id)
        }.to raise_error(OldHubspot::ConfigurationError)
      end
    end

    context "when all specified parameters are present" do
      it "does not raise an error" do
        OldHubspot::Config.configure(hapikey: "123abc", portal_id: "456def")

        expect {
          OldHubspot::Config.ensure!(:portal_id)
        }.not_to raise_error
      end
    end
  end
end
