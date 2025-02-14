RSpec.describe OldHubspot::CompanyProperties do
  describe '.add_default_parameters' do
    let(:opts) { {} }
    subject { OldHubspot::CompanyProperties.add_default_parameters(opts) }
    context 'default parameters' do
      context 'without property parameter' do
        its([:property]) { should == 'email' }
      end

      context 'with property parameter' do
        let(:opts) { {property: 'name' } }
        its([:property]) { should == 'name'}
      end
    end
  end

  before { OldHubspot.configure(hapikey: ENV.fetch("HUBSPOT_HAPI_KEY", "demo")) }

  describe ".all" do
    it "should return all properties" do
      VCR.use_cassette "company_properties/all_properties" do
        OldHubspot::CompanyProperties.create!({
          "name" => "fax_number",
          "label" => "Fax Number",
          "description" => "The company fax number.",
          "groupName" => "companyinformation",
          "type" => "string",
          "fieldType" => "text"
        })

        response = OldHubspot::CompanyProperties.all

        assert_hubspot_api_request(:get, "/properties/v1/companies/properties")

        company_property_names = response.map { |property| property["name"] }
        expect(company_property_names).to include("fax_number")

        OldHubspot::CompanyProperties.delete!("fax_number")
      end
    end

    context "with included groups" do
      it "should return properties for the specified group[s]" do
        VCR.use_cassette("company_properties/filter_by_group") do
          group_a = "socialmediainformation"
          group_b = "companyinformation"

          OldHubspot::CompanyProperties.create!({
            "name" => "instagram_handle",
            "label" => "Instagram Handle",
            "description" => "The company's Instagram handle.",
            "groupName" => group_a,
            "type" => "string",
            "fieldType" => "text"
          })
          OldHubspot::CompanyProperties.create!({
            "name" => "fax_number",
            "label" => "Fax Number",
            "description" => "The company fax number.",
            "groupName" => group_b,
            "type" => "string",
            "fieldType" => "text"
          })

          response = OldHubspot::CompanyProperties.all({}, { include: [group_a] })

          assert_hubspot_api_request(:get, "/properties/v1/companies/properties")

          group_names = response.map { |property| property["groupName"] }
          expect(group_names).to include(group_a)
          expect(group_names).not_to include(group_b)

          OldHubspot::CompanyProperties.delete!("instagram_handle")
          OldHubspot::CompanyProperties.delete!("fax_number")
        end
      end
    end

    context "with excluded groups" do
      it "does not return properties in the exluded groups(s)" do
        VCR.use_cassette("company_properties/exclude_by_group") do
          group_a = "socialmediainformation"
          group_b = "companyinformation"

          OldHubspot::CompanyProperties.create!({
            "name" => "instagram_handle",
            "label" => "Instagram Handle",
            "description" => "The company's Instagram handle.",
            "groupName" => group_a,
            "type" => "string",
            "fieldType" => "text"
          })
          OldHubspot::CompanyProperties.create!({
            "name" => "fax_number",
            "label" => "Fax Number",
            "description" => "The company fax number.",
            "groupName" => group_b,
            "type" => "string",
            "fieldType" => "text"
          })

          response = OldHubspot::CompanyProperties.all({}, { exclude: [group_a] })

          assert_hubspot_api_request(:get, "/properties/v1/companies/properties")

          group_names = response.map { |property| property["groupName"] }
          expect(group_names).not_to include(group_a)
          expect(group_names).to include(group_b)

          OldHubspot::CompanyProperties.delete!("fax_number")
          OldHubspot::CompanyProperties.delete!("instagram_handle")
        end
      end
    end

    describe ".create!" do
      it "creates a company property" do
        VCR.use_cassette("company_properties/create_property") do
          name = "fax_number"

          create_params = {
            "name" => name,
            "groupName" => "companyinformation",
          }

          response = OldHubspot::CompanyProperties.create!(create_params)

          assert_hubspot_api_request(
            :post,
            "/properties/v1/companies/properties",
            body: {
              name: name,
              groupName: "companyinformation",
              options: []
            }
          )
          expect(response["name"]).to eq(name)

          OldHubspot::CompanyProperties.delete!(name)
        end
      end

      context "with no valid parameters" do
        it "returns nil" do
          response = OldHubspot::CompanyProperties.create!({})

          expect(response).to be nil
        end
      end
    end

    describe ".update!" do
      it "updates the company property" do
        VCR.use_cassette "company_properties/update_property" do
          name = "fax_number"
          label = "fax number label"
          new_label = "new fax number label"

          OldHubspot::CompanyProperties.create!({
            "groupName" => "companyinformation",
            "label" => label,
            "name" => name,
            "type" => "string",
          })

          update_params = {
            "groupName" => "companyinformation",
            "label" => new_label,
            "type" => "string",
          }

          response = OldHubspot::CompanyProperties.update!(name, update_params)

          assert_hubspot_api_request(
            :put,
            "/properties/v1/companies/properties/named",
            body: {
              groupName: "companyinformation",
              label: new_label,
              options: [],
              type: "string",
            }
          )
          expect(response["label"]).to eq(new_label)

          OldHubspot::CompanyProperties.delete!(name)
        end
      end

      context "with no valid parameters" do
        it "returns nil" do
          company_property_name = "fax_number"
          params = {}

          response = OldHubspot::CompanyProperties.update!(
            company_property_name,
            params
          )

          expect(response).to be nil
        end
      end
    end

    describe ".delete!" do
      it "deletes the company property" do
        VCR.use_cassette("company_properties/delete_property") do
          name = "fax_number"

          OldHubspot::CompanyProperties.create!({
            "groupName" => "companyinformation",
            "name" => name,
            "type" => "string",
          })

          response = OldHubspot::CompanyProperties.delete!(name)

          assert_hubspot_api_request(
            :delete,
            "properties/v1/companies/properties/named/#{name}"
          )

          expect(response).to be nil
        end
      end

      context "when the company property does not exist" do
        it "raises an error" do
          VCR.use_cassette("company_properties/delete_non_property") do
            expect {
              OldHubspot::CompanyProperties.delete!("non-existent")
            }.to raise_error(OldHubspot::RequestError)
          end
        end
      end
    end
  end

  describe "Groups" do
    describe ".groups" do
      it "returns all groups" do
        VCR.use_cassette("company_properties/all_groups") do
          group_name = "group_awesome"
          OldHubspot::CompanyProperties.create_group!(name: group_name)

          response = OldHubspot::CompanyProperties.groups

          assert_hubspot_api_request(:get, "/properties/v1/companies/groups")

          group_names = response.map { |group| group["name"] }
          expect(group_names).to include(group_name)

          OldHubspot::CompanyProperties.delete_group!(group_name)
        end
      end

      context "when included groups are provided" do
        it "returns the specified groups" do
          VCR.use_cassette("company_properties/groups_included") do
            group_a = "socialmediainformation"
            group_b = "companyinformation"

            OldHubspot::CompanyProperties.create!({
              "name" => "instagram_handle",
              "label" => "Instagram Handle",
              "description" => "The company's Instagram handle.",
              "groupName" => group_a,
              "type" => "string",
              "fieldType" => "text"
            })
            OldHubspot::CompanyProperties.create!({
              "name" => "fax_number",
              "label" => "Fax Number",
              "description" => "The company fax number.",
              "groupName" => group_b,
              "type" => "string",
              "fieldType" => "text"
            })

            response = OldHubspot::CompanyProperties.groups(
              {},
              { include: group_a }
            )

            assert_hubspot_api_request(:get, "/properties/v1/companies/groups")

            OldHubspot::CompanyProperties.delete!("instagram_handle")
            OldHubspot::CompanyProperties.delete!("fax_number")

            group_names = response.map { |group| group["name"] }
            expect(group_names).to include(group_a)
            expect(group_names).not_to include(group_b)
          end
        end
      end

      context "when excluded groups are provided" do
        it "returns groups that were not excluded" do
          VCR.use_cassette("company_properties/groups_excluded") do
            group_a = "socialmediainformation"
            group_b = "companyinformation"

            OldHubspot::CompanyProperties.create!({
              "name" => "instagram_handle",
              "label" => "Instagram Handle",
              "description" => "The company's Instagram handle.",
              "groupName" => group_a,
              "type" => "string",
              "fieldType" => "text"
            })
            OldHubspot::CompanyProperties.create!({
              "name" => "fax_number",
              "label" => "Fax Number",
              "description" => "The company fax number.",
              "groupName" => group_b,
              "type" => "string",
              "fieldType" => "text"
            })

            response = OldHubspot::CompanyProperties.groups(
              {},
              { exclude: group_a }
            )

            assert_hubspot_api_request(:get, "/properties/v1/companies/groups")

            group_names = response.map { |group| group["name"] }
            expect(group_names).not_to include(group_a)
            expect(group_names).to include(group_b)

            OldHubspot::CompanyProperties.delete!("instagram_handle")
            OldHubspot::CompanyProperties.delete!("fax_number")
          end
        end
      end
    end

    let(:params) { { 'name' => 'ff_group1', 'displayName' => 'Test Group One', 'displayOrder' => 100, 'badParam' => 99 } }

    describe '.create_group!' do
      context 'with no valid parameters' do
        it 'should return nil' do
          expect(OldHubspot::CompanyProperties.create_group!({})).to be(nil)
        end
      end

      context 'with mixed parameters' do
        cassette 'company_properties/create_group'

        it 'should return the valid parameters' do
          response = OldHubspot::CompanyProperties.create_group!(params)
          expect(OldHubspot::CompanyProperties.same?(response, params)).to be true
        end
      end

      context 'with some valid parameters' do
        cassette 'company_properties/create_group_some_params'

        let(:sub_params) { params.select { |k, _| k != 'displayName' } }

        it 'should return the valid parameters' do
          params['name'] = 'ff_group235'
          response       = OldHubspot::CompanyProperties.create_group!(sub_params)
          expect(OldHubspot::CompanyProperties.same?(response, sub_params)).to be true
        end
      end
    end

    describe '.update_group!' do
      context 'with no valid parameters' do

        it 'should return nil ' do
          expect(OldHubspot::CompanyProperties.update_group!(params['name'], {})).to be(nil)
        end
      end

      context 'with mixed parameters' do
        cassette 'company_properties/update_group'

        it 'should return the valid parameters' do
          params['displayName'] = 'Test Group OneA'

          response = OldHubspot::CompanyProperties.update_group!(params['name'], params)
          expect(OldHubspot::CompanyProperties.same?(response, params)).to be true
        end
      end

    end

    describe '.delete_group!' do
      let(:name) { params['name'] }

      context 'with existing group' do
        cassette 'company_properties/delete_group'

        it 'should return nil' do
          expect(OldHubspot::CompanyProperties.delete_group!(name)).to eq(nil)
        end
      end

      context 'with non-existent group' do
        cassette 'company_properties/delete_non_group'

        it 'should raise an error' do
          expect { OldHubspot::CompanyProperties.delete_group!(name) }.to raise_error(OldHubspot::RequestError)
        end
      end
    end
  end
end
