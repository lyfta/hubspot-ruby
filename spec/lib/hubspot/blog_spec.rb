require 'timecop'

describe OldHubspot do
  before { Timecop.freeze(Time.utc(2012, 'Oct', 10)) }
  after { Timecop.return }

  let(:last_blog_id) { Hubspot::Blog.list.last['id'] }
  let(:last_blog_post_id) { Hubspot::Blog.list.last.posts.first['id'] }

  describe OldHubspot::Blog do
    describe ".list" do
      it "returns a list of blogs" do
        VCR.use_cassette("blog_list") do
          result = OldHubspot::Blog.list

          expect(result).to be_kind_of(Array)
          expect(result.first).to be_a(OldHubspot::Blog)
        end
      end
    end

    describe ".find_by_id" do
      it "retrieves a blog by id" do
        VCR.use_cassette("blog_list") do
          result = Hubspot::Blog.find_by_id(last_blog_id)

          expect(result).to be_a(OldHubspot::Blog)
        end
      end
    end

    describe "#[]" do
      it "returns the value for the given key" do
        data = {
          "id" => 123,
          "name" => "Demo",
        }
        blog = OldHubspot::Blog.new(data)

        expect(blog["id"]).to eq(data["id"])
        expect(blog["name"]).to eq(data["name"])
      end

      context "when the value is unknown" do
        it "returns nil" do
          blog = OldHubspot::Blog.new({})

          expect(blog["nope"]).to be_nil
        end
      end
    end

    describe "#posts" do
      it "returns published blog posts created in the last 2 months" do
        VCR.use_cassette("blog_posts/all_blog_posts") do
          blog_id = last_blog_id
          created_gt = timestamp_in_milliseconds(Time.now - 2.months)
          blog = OldHubspot::Blog.new({ "id" => blog_id })

          result = blog.posts

          expect(result).to be_kind_of(Array)
        end
      end

      it "includes given parameters in the request" do
        VCR.use_cassette("blog_posts/filter_blog_posts") do
          created_gt = timestamp_in_milliseconds(Time.now - 2.months)

          blog = OldHubspot::Blog.new({ "id" => last_blog_id })

          result = blog.posts({ state: "DRAFT" })

          expect(result).to be_kind_of(Array)
        end
      end

      it "raises when given an unknown state" do
        blog = OldHubspot::Blog.new({})

        expect {
          blog.posts({ state: "unknown" })
        }.to raise_error(OldHubspot::InvalidParams, "State parameter was invalid")
      end
    end
  end

  describe OldHubspot::BlogPost do
    describe "#created_at" do
      it "returns the created timestamp as a Time" do
        timestamp = timestamp_in_milliseconds(Time.now)
        blog_post = OldHubspot::BlogPost.new({ "created" => timestamp })

        expect(blog_post.created_at).to eq(Time.at(timestamp/1000))
      end
    end

    describe ".find_by_blog_post_id" do
      it "retrieves a blog post by id" do
        VCR.use_cassette "blog_posts" do
          result = OldHubspot::BlogPost.find_by_blog_post_id(last_blog_post_id)

          expect(result).to be_a(OldHubspot::BlogPost)
        end
      end
    end

    describe "#topics" do
      it "returns the list of topics" do
        VCR.use_cassette "blog_posts" do
          blog_post = OldHubspot::BlogPost.find_by_blog_post_id(last_blog_post_id)

          topics = blog_post.topics

          expect(topics).to be_kind_of(Array)
          expect(topics.first).to be_a(OldHubspot::Topic)
        end
      end

      context "when the blog post does not have topics" do
        it "returns an empty list" do
          blog_post = OldHubspot::BlogPost.new({ "topic_ids" => [] })

          topics = blog_post.topics

          expect(topics).to be_empty
        end
      end
    end
  end

  def hubspot_api_url(path)
    URI.join(OldHubspot::Config.base_url, path)
  end

  def timestamp_in_milliseconds(time)
    time.to_i * 1000
  end
end
