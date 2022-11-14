describe OldHubspot::Engagement do
  let(:contact) { OldHubspot::Contact.create("#{SecureRandom.hex}@hubspot.com") }
  let(:engagement) { OldHubspot::EngagementNote.create!(contact.id, "foo") }

  # http://developers.hubspot.com/docs/methods/contacts/get_contact

  describe "#initialize" do
    subject{ OldHubspot::Engagement.new(example_engagement_hash) }

    let(:example_engagement_hash) { { 'engagement' => { 'id' => 3981023, 'portalId' => 62515, 'associations' => {} } } }

    it  { should be_an_instance_of OldHubspot::Engagement }
    its (:id) { should == 3981023 }
  end

  describe 'EngagementNote' do
    describe ".create!" do
      cassette "engagement_create"
      body = "Test note"
      subject { OldHubspot::EngagementNote.create!(nil, body) }
      its(:id) { should_not be_nil }
      its(:body) { should eql body }
    end

    describe ".find" do
      cassette "engagement_find"
      let(:engagement) {OldHubspot::EngagementNote.new(example_engagement_hash)}

      it 'must find by the engagement id' do
        find_engagement = OldHubspot::EngagementNote.find(engagement.id)
        find_engagement.id.should eql engagement.id
        find_engagement.body.should eql engagement.body
      end
    end

    describe ".find_by_company" do
      cassette "engagement_find_by_country"

      let(:company) { OldHubspot::Company.create(name: SecureRandom.hex) }
      before do
        engagement.class.associate!(
          engagement.id,
          "Company",
          company.id
        )
      end

      it 'must find by company id' do
        find_engagements = OldHubspot::EngagementNote.find_by_company(company.id)
        find_engagements.should_not be_nil
        find_engagements.any?{|engagement| engagement.id == engagement.id and engagement.body == engagement.body}.should be true
      end
    end

    describe ".find_by_contact" do
      cassette "engagement_find_by_contact"

      let(:engagement) {OldHubspot::EngagementNote.new(example_associated_engagement_hash)}

      it 'must find by contact id' do
        find_engagements = OldHubspot::EngagementNote.find_by_contact(engagement.associations["contactIds"].first)
        find_engagements.should_not be_nil
        find_engagements.any?{|engagement| engagement.id == engagement.id and engagement.body == engagement.body}.should be true
      end
    end

    describe ".find_by_association" do
      cassette "engagement_find_by_association"

      it 'must raise for fake association type' do
        expect {
          OldHubspot::EngagementNote.find_by_association(1, 'FAKE_TYPE')
        }.to raise_error
      end
    end

    describe ".all" do
      cassette "find_all_engagements"

      it 'must get the engagements list' do
        engagement
        engagements = OldHubspot::Engagement.all

        first = engagements['engagements'].first

        expect(first).to be_a OldHubspot::Engagement
      end

      it 'must filter only 2 engagements' do
        3.times { OldHubspot::EngagementNote.create!(contact.id, "foo") }
        engagements = OldHubspot::Engagement.all(limit: 2)
        expect(engagements['engagements'].size).to eql 2
      end
    end

    describe ".associate!" do
      cassette "engagement_associate"

      let(:engagement) { OldHubspot::EngagementNote.create!(nil, 'note') }
      let(:contact) { OldHubspot::Contact.create("#{SecureRandom.hex}@hubspot.com") }
      subject { OldHubspot::Engagement.associate!(engagement.id, 'contact', contact.id) }

      it 'associate an engagement to a resource' do
        subject
        found_by_contact = OldHubspot::Engagement.find_by_contact(contact.id)
        expect(found_by_contact.first.id).to eql engagement.id
      end
    end

    describe '#destroy!' do
      cassette 'engagement_destroy'

      let(:engagement) {OldHubspot::EngagementNote.create!(nil, 'test note') }

      it 'should remove from hubspot' do
        expect(OldHubspot::Engagement.find(engagement.id)).to_not be_nil

        expect(engagement.destroy!).to be true
        expect(engagement.destroyed?).to be true

        expect(OldHubspot::Engagement.find(engagement.id)).to be_nil
      end
    end
  end

  describe 'EngagementCall' do
    describe ".create!" do
      cassette "engagement_call_create"
      body = "Test call"
      subject { OldHubspot::EngagementCall.create!(nil, body, 0) }
      its(:id) { should_not be_nil }
      its(:body) { should eql body }
    end

    describe ".find" do
      cassette "engagement_call_find"

      let(:engagement) { OldHubspot::EngagementCall.create!(contact.id, "foo", 42) }

      it 'must find by the engagement id' do
        find_engagement = OldHubspot::EngagementCall.find(engagement.id)
        find_engagement.id.should eql engagement.id
        find_engagement.body.should eql engagement.body
      end
    end

    describe '#destroy!' do
      cassette 'engagement_call_destroy'

      let(:engagement) { OldHubspot::EngagementCall.create!(nil, 'test call', 0) }

      it 'should remove from hubspot' do
        expect(OldHubspot::Engagement.find(engagement.id)).to_not be_nil

        expect(engagement.destroy!).to be true
        expect(engagement.destroyed?).to be true

        expect(OldHubspot::Engagement.find(engagement.id)).to be_nil
      end
    end
  end
end
