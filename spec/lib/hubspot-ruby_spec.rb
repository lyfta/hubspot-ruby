describe OldHubspot do
  describe "#configure" do
    it "delegates a call to Hubspot::Config.configure" do
      mock(OldHubspot::Config).configure({ hapikey: "demo"})
      OldHubspot.configure hapikey: "demo"
    end
  end
end
