# frozen_string_literal: true

RSpec.describe FirebaseDynamicLink::Client do
  before(:all) { FirebaseDynamicLink.reset_config }
  let(:connection_failed_class) do
    Class.new do
      def post(*)
        raise Faraday::ConnectionFailed, "test"
      end
    end
  end
  let(:timout_error_class) do
    Class.new do
      def post(*)
        raise Faraday::TimeoutError, "test"
      end
    end
  end

  before do
    FirebaseDynamicLink.configure do |config|
      config.api_key = ENV["API_KEY"]
      config.dynamic_link_domain = ENV["DYNAMIC_LINK_DOMAIN"]
    end
  end

  describe "#shorten_link" do
    it "shorten link correctly" do
      link = "http://saiqulhaq.com"
      VCR.use_cassette("shorten_link-SHORT") do
        options = { suffix_option: "SHORT" }
        result = subject.shorten_link(link, options)
        expect(result[:link]).to_not eq("")
        expect(result[:link]).to_not eq(link)
      end

      VCR.use_cassette("shorten_link-UNGUESSABLE") do
        options = { suffix_option: "UNGUESSABLE", timout: 5 }
        result = subject.shorten_link(link, options)
        expect(result[:link]).to_not eq("")
        expect(result[:link]).to_not eq(link)
      end
    end

    it "raise FirebaseDynamicLink::ConnectionError if Faraday::ConnectionFailed raised" do
      allow_any_instance_of(described_class).to receive(:connection).and_return(connection_failed_class.new)
      expect do
        subject.shorten_link("http://saiqulhaq.com")
      end.to raise_error(FirebaseDynamicLink::ConnectionError)
    end

    it "raise FirebaseDynamicLink::ConnectionError if Faraday::TimeoutError raised" do
      allow_any_instance_of(described_class).to receive(:connection).and_return(timout_error_class.new)
      expect do
        subject.shorten_link("http://saiqulhaq.com")
      end.to raise_error(FirebaseDynamicLink::ConnectionError)
    end
  end

  describe "#shorten_parameters" do
    let(:link) { "http://saiqulhaq.com/asldkj" }
    let(:parameters) do
      string = "foo"
      {
        link: link,
        android_info: {
          android_package_name: "com.foo.name"
        },
        ios_info: {
          ios_bundle_id: string,
          ios_fallback_link: string,
          ios_custom_scheme: string,
          ios_ipad_fallback_link: string,
          ios_ipad_bundle_id: string,
          ios_app_store_id: string
        },
        navigation_info: {
          enable_forced_redirect: [true, false].sample
        },
        analytics_info: {
          google_play_analytics: {
            utm_source: "custom"
          },
          itunes_connect_analytics: {
            at: string
          }
        },
        social_meta_tag_info: {
          social_title: string,
          social_description: string,
          social_image_link: string
        }
      }
    end
    it "shorten link correctly" do
      VCR.use_cassette("shorten_parameters-SHORT") do
        options = {
          suffix_option: "SHORT",
          # dynamic_link_domain: 'foo' # optional
        }

        expect do
          result = subject.shorten_parameters(parameters, options)
          expect(result[:link]).to_not eq("")
          expect(result[:link]).to_not eq(link)
        end.to_not raise_error
      end

      VCR.use_cassette("shorten_parameters-UNGUESSABLE") do
        options = {
          suffix_option: "UNGUESSABLE",
          # dynamic_link_domain: 'foo' # optional
        }

        expect do
          result = subject.shorten_parameters(parameters, options)
          expect(result[:link]).to_not eq("")
          expect(result[:link]).to_not eq(link)
        end.to_not raise_error
      end
    end

    it "raise FirebaseDynamicLink::ConnectionError if Faraday::ConnectionFailed raised" do
      allow_any_instance_of(described_class).to receive(:connection).and_return(connection_failed_class.new)
      expect do
        subject.shorten_parameters(parameters)
      end.to raise_error(FirebaseDynamicLink::ConnectionError)
    end

    it "raise FirebaseDynamicLink::ConnectionError if Faraday::TimeoutError raised" do
      allow_any_instance_of(described_class).to receive(:connection).and_return(timout_error_class.new)
      expect do
        subject.shorten_link(parameters)
      end.to raise_error(FirebaseDynamicLink::ConnectionError)
    end
  end
end
