require 'hubspot/utils'

module OldHubspot
  #
  # HubSpot Engagements API
  #
  # {http://developers.hubspot.com/docs/methods/engagements/create_engagement}
  #
  class Engagement
    CREATE_ENGAGMEMENT_PATH = '/engagements/v1/engagements'
    ENGAGEMENT_PATH = '/engagements/v1/engagements/:engagement_id'
    ASSOCIATE_ENGAGEMENT_PATH = '/engagements/v1/engagements/:engagement_id/associations/:object_type/:object_vid'
    GET_ASSOCIATED_ENGAGEMENTS = '/engagements/v1/engagements/associated/:objectType/:objectId/paged'

    attr_reader :id
    attr_reader :engagement
    attr_reader :associations
    attr_reader :attachments
    attr_reader :metadata

    def initialize(response_hash)

      @engagement = response_hash["engagement"]
      @associations = response_hash["associations"]
      @attachments = response_hash["attachments"]
      @metadata = response_hash["metadata"]
      @id = engagement["id"]
    end

    class << self
      def create!(params={})
        response = OldHubspot::Connection.post_json(CREATE_ENGAGMEMENT_PATH, params: {}, body: params )
        new(HashWithIndifferentAccess.new(response))
      end

      def find(engagement_id)
        begin
          response = OldHubspot::Connection.get_json(ENGAGEMENT_PATH, { engagement_id: engagement_id })
          response ? new(HashWithIndifferentAccess.new(response)) : nil
        rescue OldHubspot::RequestError => ex
          if ex.response.code == 404
            return nil
          else
            raise ex
          end
        end
      end

      def find_by_company(company_id)
        find_by_association company_id, 'COMPANY'
      end

      def find_by_contact(contact_id)
        find_by_association contact_id, 'CONTACT'
      end

      def find_by_association(association_id, association_type)
        path = GET_ASSOCIATED_ENGAGEMENTS
        params = { objectType: association_type, objectId: association_id }
        raise OldHubspot::InvalidParams, 'expecting Integer parameter' unless association_id.try(:is_a?, Integer)
        raise OldHubspot::InvalidParams, 'expecting String parameter' unless association_type.try(:is_a?, String)

        engagements = []
        begin
          response = OldHubspot::Connection.get_json(path, params)
          engagements = response["results"].try(:map) { |engagement| new(engagement) }
        rescue => e
          raise e unless e.message =~ /not found/
        end
        engagements
      end

      # Associates an engagement with an object
      # {https://developers.hubspot.com/docs/methods/engagements/associate_engagement}
      # @param engagement_id [int] id of the engagement to associate
      # @param object_type [string] one of contact, company, or deal
      # @param object_vid [int] id of the contact, company, or deal to associate
      def associate!(engagement_id, object_type, object_vid)
        OldHubspot::Connection.put_json(ASSOCIATE_ENGAGEMENT_PATH,
                                        params: {
                                       engagement_id: engagement_id,
                                       object_type: object_type,
                                       object_vid: object_vid
                                     })
      end
    end

    # Archives the engagement in hubspot
    # {http://developers.hubspot.com/docs/methods/engagements/delete-engagement}
    # @return [TrueClass] true
    def destroy!
      OldHubspot::Connection.delete_json(ENGAGEMENT_PATH, { engagement_id: id})
      @destroyed = true
    end

    def destroyed?
      !!@destroyed
    end

    def [](property)
      @properties[property]
    end

    # Updates the properties of an engagement
    # {http://developers.hubspot.com/docs/methods/engagements/update_engagement}
    # @param params [Hash] hash of properties to update
    # @return [OldHubspot::Engagement] self
    def update!(params)
      data = {
        engagement: params[:engagement]     || engagement,
        associations: params[:associations] || associations,
        attachments: params[:attachments]   || attachments,
        metadata: params[:metadata]         || metadata
      }

      OldHubspot::Connection.put_json(ENGAGEMENT_PATH, params: { engagement_id: id }, body: data)
      self
    end
  end

  class EngagementNote < Engagement
    def body
      metadata['body']
    end

    def contact_ids
      associations['contactIds']
    end

    class << self
      def create!(contact_id, note_body, owner_id = nil, deal_id = nil)
        data = {
          engagement: {
            type: 'NOTE'
          },
          associations: {
            contactIds: [contact_id]
          },
          metadata: {
            body: note_body
          }
        }

        # if the owner id has been provided, append it to the engagement
        data[:engagement][:owner_id] = owner_id if owner_id
        # if the deal id has been provided, associate the note with the deal
        data[:associations][:dealIds] = [deal_id] if deal_id

        super(data)
      end
    end
  end

  class EngagementCall < Engagement
    def body
      metadata['body']
    end

    def contact_ids
      associations['contactIds']
    end

    def company_ids
      associations['companyIds']
    end

    def deal_ids
      associations['dealIds']
    end

    class << self
      def create!(contact_vid, body, duration, owner_id = nil, deal_id = nil, status = 'COMPLETED', time = nil)
        data = {
          engagement: {
            type: 'CALL'
          },
          associations: {
            contactIds: [contact_vid],
            dealIds: [deal_id],
            ownerIds: [owner_id]
          },
          metadata: {
            body: body,
            status: status,
            durationMilliseconds: duration
          }
        }

        data[:engagement][:timestamp] = (time.to_i) * 1000 if time
        data[:engagement][:owner_id] = owner_id if owner_id

        super(data)
      end
    end
  end
end
