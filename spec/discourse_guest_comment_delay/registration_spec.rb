# frozen_string_literal: true

RSpec.describe DiscourseGuestCommentDelay do
  let(:plugin_instance) do
    instance_double(
      "PluginInstance",
      register_category_custom_field_type: nil,
      register_preloaded_category_custom_fields: nil,
      add_to_serializer: nil
    )
  end

  around do |example|
    original_category = Object.const_defined?(:Category) ? Category : nil
    original_application_controller = Object.const_defined?(:ApplicationController) ? ApplicationController : nil
    original_posts_controller = Object.const_defined?(:PostsController) ? PostsController : nil
    original_basic_post_serializer = Object.const_defined?(:BasicPostSerializer) ? BasicPostSerializer : nil
    original_post_serializer = Object.const_defined?(:PostSerializer) ? PostSerializer : nil
    original_topic_view = Object.const_defined?(:TopicView) ? TopicView : nil

    Object.send(:remove_const, :Category) if Object.const_defined?(:Category)
    Object.send(:remove_const, :ApplicationController) if Object.const_defined?(:ApplicationController)
    Object.send(:remove_const, :PostsController) if Object.const_defined?(:PostsController)
    Object.send(:remove_const, :BasicPostSerializer) if Object.const_defined?(:BasicPostSerializer)
    Object.send(:remove_const, :PostSerializer) if Object.const_defined?(:PostSerializer)
    Object.send(:remove_const, :TopicView) if Object.const_defined?(:TopicView)

    category_class = Class.new do
      class << self
        attr_reader :registered_fields

        def register_custom_field_type(name, type)
          @registered_fields ||= []
          @registered_fields << [name, type]
        end
      end
    end

    application_controller_class = Class.new do
      class << self
        attr_reader :prepended_modules

        def prepend(mod)
          @prepended_modules ||= []
          @prepended_modules << mod
          super
        end
      end
    end

    posts_controller_class = Class.new do
      class << self
        attr_reader :prepended_modules

        def prepend(mod)
          @prepended_modules ||= []
          @prepended_modules << mod
          super
        end
      end
    end

    basic_post_serializer_class = Class.new

    post_serializer_class = Class.new(basic_post_serializer_class) do
      class << self
        attr_reader :prepended_modules

        def prepend(mod)
          @prepended_modules ||= []
          @prepended_modules << mod
          super
        end
      end
    end

    topic_view_class = Class.new do
      class << self
        attr_reader :prepended_modules

        def prepend(mod)
          @prepended_modules ||= []
          @prepended_modules << mod
          super
        end
      end
    end

    Object.const_set(:Category, category_class)
    Object.const_set(:ApplicationController, application_controller_class)
    Object.const_set(:PostsController, posts_controller_class)
    Object.const_set(:BasicPostSerializer, basic_post_serializer_class)
    Object.const_set(:PostSerializer, post_serializer_class)
    Object.const_set(:TopicView, topic_view_class)

    example.run
  ensure
    Object.send(:remove_const, :Category) if Object.const_defined?(:Category)
    Object.send(:remove_const, :ApplicationController) if Object.const_defined?(:ApplicationController)
    Object.send(:remove_const, :PostsController) if Object.const_defined?(:PostsController)
    Object.send(:remove_const, :BasicPostSerializer) if Object.const_defined?(:BasicPostSerializer)
    Object.send(:remove_const, :PostSerializer) if Object.const_defined?(:PostSerializer)
    Object.send(:remove_const, :TopicView) if Object.const_defined?(:TopicView)
    Object.const_set(:Category, original_category) if original_category
    Object.const_set(:ApplicationController, original_application_controller) if original_application_controller
    Object.const_set(:PostsController, original_posts_controller) if original_posts_controller
    Object.const_set(:BasicPostSerializer, original_basic_post_serializer) if original_basic_post_serializer
    Object.const_set(:PostSerializer, original_post_serializer) if original_post_serializer
    Object.const_set(:TopicView, original_topic_view) if original_topic_view
  end

  it "registers the category custom field, preload, and serializer hooks" do
    expect(plugin_instance).to receive(:register_category_custom_field_type)
      .with("guest_comment_delay_minutes_override", :integer)
    expect(plugin_instance).to receive(:register_preloaded_category_custom_fields)
      .with("guest_comment_delay_minutes_override")
    expect(plugin_instance).to receive(:add_to_serializer)
      .with(:post, :guest_hidden_placeholder, hash_including(:include_condition))
    expect(plugin_instance).to receive(:add_to_serializer)
      .with(:post, :guest_hidden_delay_minutes, hash_including(:include_condition))

    described_class.register!(plugin_instance)

    expect(Category.registered_fields).to be_nil
    expect(ApplicationController.prepended_modules).to include(DiscourseGuestCommentDelay::RequestScopeExtension)
    expect(PostsController.prepended_modules).to include(DiscourseGuestCommentDelay::PostsControllerExtension)
    expect(TopicView.prepended_modules).to include(DiscourseGuestCommentDelay::TopicViewExtension)
    expect(PostSerializer.prepended_modules).to include(DiscourseGuestCommentDelay::PostSerializerExtension::Post)
  end
end
