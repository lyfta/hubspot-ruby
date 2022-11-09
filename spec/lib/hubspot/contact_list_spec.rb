describe OldHubspot::ContactList do
  # uncomment if you need to create test data in your panel.
  # note that sandboxes have a limit of 5 dynamic lists
  # before(:all) do
  #   VCR.use_cassette("create_all_lists") do
  #     25.times { Hubspot::ContactList.create!(name: SecureRandom.hex) }
  #     3.times { Hubspot::ContactList.create!(name: SecureRandom.hex, dynamic: true, filters: [[{ operator: "EQ", value: "@hubspot", property: "twitterhandle", type: "string"}]]) }
  #   end
  # end

  let(:example_contact_list_hash) do
    VCR.use_cassette("contact_list_example") do
      headers = { Authorization: "Bearer #{ENV.fetch('HUBSPOT_ACCESS_TOKEN')}" }
      response = HTTParty.get("https://api.hubapi.com/contacts/v1/lists/static?count=1", headers: headers).parsed_response
      response['lists'].first
    end
  end

  let(:static_list) do
    OldHubspot::ContactList.create!(name: "static list #{SecureRandom.hex}")
  end

  shared_examples "count and offset" do |params|
    it 'returns only the number of objects specified by count' do
      result = instance_exec(count: 2, &params[:block])
      expect(result.size).to eql 2
    end

    it 'returns objects by a specified offset' do
      non_offset_objects = instance_exec(count: 2, &params[:block])
      objects_with_offset = instance_exec(count: 2, offset: 2, &params[:block])
      expect(non_offset_objects).to_not eql objects_with_offset
    end
  end

  describe '#initialize' do
    subject { OldHubspot::ContactList.new(example_contact_list_hash) }

    it { should be_an_instance_of OldHubspot::ContactList }
    its(:id) { should be_an(Integer) }
    its(:portal_id) { should be_a(Integer) }
    its(:name) { should_not be_empty }
    its(:dynamic) { should be false }
    its(:properties) { should be_a(Hash) }
  end

  describe '#contacts' do
    cassette 'contacts_among_list'

    let(:list) { @list }

    before(:all) do
      VCR.use_cassette 'create_and_add_all_contacts' do
        @list = OldHubspot::ContactList.create!(name: "contacts list #{SecureRandom.hex}")
        25.times do
          contact = OldHubspot::Contact.create("#{SecureRandom.hex}@hubspot.com")
          @list.add(contact)
        end
      end
    end

    it 'returns by default 20 contact lists with paging data' do
      contact_data = list.contacts({bypass_cache: true, paged: true})
      contacts = contact_data['contacts']

      expect(contact_data).to have_key 'vid-offset'
      expect(contact_data).to have_key 'has-more'

      expect(contacts.count).to eql 20
      contact = contacts.first
      expect(contact).to be_a(OldHubspot::Contact)
      expect(contact.email).to_not be_empty
    end
  end

  describe '.create' do
    subject{ OldHubspot::ContactList.create!({ name: name }) }

    context 'with all required parameters' do
      cassette 'create_list'

      let(:name) { "testing list #{SecureRandom.hex}" }
      it { should be_an_instance_of OldHubspot::ContactList }
      its(:id) { should be_an(Integer) }
      its(:portal_id) { should be_an(Integer) }
      its(:dynamic) { should be false }

      context 'adding filters parameters' do
        cassette 'create_list_with_filters'

        it 'returns a ContactList object with filters set' do
          name = "list with filters #{SecureRandom.hex}"
          filters_param = [[{ operator: "EQ", value: "@hubspot", property: "twitterhandle", type: "string"}]]
          list_with_filters = OldHubspot::ContactList.create!({ name: name, filters: filters_param })
          expect(list_with_filters).to be_a(OldHubspot::ContactList)
          expect(list_with_filters.properties['filters']).to_not be_empty
        end
      end
    end

    context 'without all required parameters' do
      cassette 'fail_to_create_list'

      it 'raises an error' do
        expect { OldHubspot::ContactList.create!({ name: nil }) }.to raise_error(OldHubspot::RequestError)
      end
    end
  end

  describe '.all' do
    context 'all list types' do
      cassette 'find_all_lists'

      it 'returns by default 20 contact lists' do
        lists = OldHubspot::ContactList.all
        expect(lists.count).to eql 20

        list = lists.first
        expect(list).to be_a(OldHubspot::ContactList)
        expect(list.id).to be_an(Integer)
      end

      it_behaves_like 'count and offset', {block: ->(r) { OldHubspot::ContactList.all(r) }}
    end

    context 'static lists' do
      cassette 'find_all_stastic_lists'

      it 'returns by defaut all the static contact lists' do
        lists = OldHubspot::ContactList.all(static: true)
        expect(lists.count).to be > 2

        list = lists.first
        expect(list).to be_a(OldHubspot::ContactList)
        expect(list.dynamic).to be false
      end
    end

    context 'dynamic lists' do
      cassette 'find_all_dynamic_lists'

      it 'returns by defaut all the dynamic contact lists' do
        lists = OldHubspot::ContactList.all(dynamic: true)
        expect(lists.count).to be > 2

        list = lists.first
        expect(list).to be_a(OldHubspot::ContactList)
        expect(list.dynamic).to be true
      end
    end
  end

  describe '.find' do
    context 'given an id' do
      cassette "contact_list_find"
      subject { OldHubspot::ContactList.find(id) }

      let(:list) { OldHubspot::ContactList.new(example_contact_list_hash) }

      context 'when the contact list is found' do
        let(:id) { list.id.to_i }
        it { should be_an_instance_of OldHubspot::ContactList }
        its(:name) { should == list.name }

        context "string id" do
          let(:id) { list.id.to_s }
          it { should be_an_instance_of OldHubspot::ContactList }
        end
      end

      context 'Wrong parameter type given' do
        it 'raises an error' do
          expect { OldHubspot::ContactList.find({ foo: :bar }) }.to raise_error(OldHubspot::InvalidParams)
        end
      end

      context 'when the contact list is not found' do
        it 'raises an error' do
          expect { OldHubspot::ContactList.find(-1) }.to raise_error(OldHubspot::NotFoundError)
        end
      end
    end

    context 'given a list of ids' do
      cassette "contact_list_batch_find"

      let(:list1) { OldHubspot::ContactList.create!(name: SecureRandom.hex) }
      let(:list2) { OldHubspot::ContactList.create!(name: SecureRandom.hex) }
      let(:list3) { OldHubspot::ContactList.create!(name: SecureRandom.hex) }

      it 'find lists of contacts' do
        lists = OldHubspot::ContactList.find([list1.id,list2.id,list3.id])
        list = lists.first
        expect(list).to be_a(Hubspot::ContactList)
        expect(list.id).to be == list1.id
        expect(lists.second.id).to be == list2.id
        expect(lists.last.id).to be == list3.id
      end
    end
  end

  describe "#add" do
    context "for a static list" do
      it "adds the contact to the contact list" do
        VCR.use_cassette("contact_lists/add_contact") do
          contact = OldHubspot::Contact.create("#{SecureRandom.hex}@example.com")
          contact_list_params = { name: "my-contacts-list-#{SecureRandom.hex}" }
          contact_list = OldHubspot::ContactList.create!(contact_list_params)

          result = contact_list.add([contact])

          expect(result).to be true

          contact.delete
          contact_list.destroy!
        end
      end

      context "when the contact already exists in the contact list" do
        it "returns false" do
          VCR.use_cassette("contact_lists/add_existing_contact") do
            contact = OldHubspot::Contact.create("#{SecureRandom.hex}@example.com")

            contact_list_params = { name: "my-contacts-list-#{SecureRandom.hex}" }
            contact_list = OldHubspot::ContactList.create!(contact_list_params)
            contact_list.add([contact])

            result = contact_list.add([contact])

            expect(result).to be true

            contact.delete
            contact_list.destroy!
          end
        end
      end
    end

    context "for a dynamic list" do
      it "raises an error as dynamic lists add contacts via on filters" do
        VCR.use_cassette("contact_list/add_contact_to_dynamic_list") do
          contact = OldHubspot::Contact.create("#{SecureRandom.hex}@example.com")
          contact_list_params = {
            name: "my-contacts-list-#{SecureRandom.hex}",
            dynamic: true,
            "filters": [
              [
                {
                  "operator": "EQ",
                  "property": "email",
                  "type": "string",
                  "value": "@hubspot.com"
                },
              ],
            ],
          }
          contact_list = OldHubspot::ContactList.create!(contact_list_params)

          expect {
            contact_list.add(contact)
          }.to raise_error(OldHubspot::RequestError)
        end
      end
    end
  end

  describe '#remove' do
    cassette "remove_contacts_from_lists"

    context 'static list' do
      it 'returns true if removes all contacts in batch mode' do
        list = OldHubspot::ContactList.new(example_contact_list_hash)
        contacts = list.contacts(count: 2)
        expect(list.remove([contacts.first, contacts.last])).to be true
      end

      it 'returns false if the contact cannot be removed' do
        contact_not_present_in_list = OldHubspot::Contact.new(1234)
        expect(static_list.remove(contact_not_present_in_list)).to be false
      end
    end
  end

  describe '#update!' do
    cassette "contact_list_update"

    let(:params) { { name: "updated list name" } }
    subject { static_list.update!(params) }

    it { should be_an_instance_of Hubspot::ContactList }
    its(:name){ should == params[:name] }

    after { static_list.destroy! }
  end

  describe '#destroy!' do
    cassette "contact_list_destroy"

    subject{ static_list.destroy! }

    it { should be true }

    it "should be destroyed" do
      subject
      expect(static_list).to be_destroyed
    end
  end
end
