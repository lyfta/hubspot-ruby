RSpec.describe OldHubspot do
  describe ".configure" do
    it "delegates .configure to Hubspot::Config.configure" do
      options = { hapikey: "demo" }
      allow(OldHubspot::Config).to receive(:configure).with(options)

      OldHubspot.configure(options)

      expect(OldHubspot::Config).to have_received(:configure).with(options)
    end
  end
end
