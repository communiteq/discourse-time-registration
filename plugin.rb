# name: discourse-time-registration
# about: Time Registration for Discourse
# version: 1.0
# authors: Communiteq

enabled_site_setting :time_registration_enabled

register_asset "stylesheets/common.scss"

register_svg_icon "stopwatch" if respond_to?(:register_svg_icon)

after_initialize do
  module ::DiscourseTimeRegistration
    PLUGIN_NAME ||= "discourse-time-registration".freeze

    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace DiscourseTimeRegistration
    end
  end

  # Register Custom Fields
  User.register_custom_field_type "active_time_registration_post_id", :integer

  # Whitelist fields for serialization so the frontend can see them
  DiscoursePluginRegistry.serialized_current_user_fields << "active_time_registration_post_id"

  # Register Post Custom Fields
  Post.register_custom_field_type "time_registration_start", :integer
  Post.register_custom_field_type "time_registration_end", :integer
  Post.register_custom_field_type "time_registration_user", :integer
  Post.register_custom_field_type "time_registration_description", :string

  # Add fields to PostSerializer so they are available in the JSON
  add_to_serializer(:post, :time_registration_start) { object.custom_fields["time_registration_start"] }
  add_to_serializer(:post, :time_registration_end) { object.custom_fields["time_registration_end"] }
  add_to_serializer(:post, :time_registration_user) { object.custom_fields["time_registration_user"] }
  add_to_serializer(:post, :time_registration_description) { object.custom_fields["time_registration_description"] }

  # Register Post Custom Fields (no need to serialize all of them to everyone, usually)
  # We will handle specific serialization in the controller or serializer extensions if needed.

  require_dependency "application_controller"

  class DiscourseTimeRegistration::TimeTrackingController < ::ApplicationController
    requires_plugin DiscourseTimeRegistration::PLUGIN_NAME

    before_action :ensure_logged_in
    before_action :ensure_can_track_time

    def toggle
      active_post_id = current_user.custom_fields["active_time_registration_post_id"]

      if active_post_id.present?
        stop_timer(active_post_id)
      else
        start_timer
      end
    end

    private

    def ensure_can_track_time
      return if current_user.admin?

      allowed_groups = SiteSetting.time_registration_groups.split("|").map(&:to_i)
      unless current_user.groups.where(id: allowed_groups).exists?
        raise Discourse::InvalidAccess.new("You are not in a time registration group")
      end
    end

    def start_timer
      topic_id = params.require(:topic_id)
      description = params[:description]

      topic = Topic.find_by(id: topic_id)
      raise Discourse::NotFound unless topic

      # Create a small action post
      post = PostCreator.create!(
        current_user,
        topic_id: topic.id,
        post_type: Post.types[:small_action],
        action_code: "time_registration",
        raw: I18n.t("time_registration.started_action", description: description.presence || I18n.t("time_registration.no_description")),
        skip_validations: true
      )

      if post
        # Set Post Custom Fields
        post.custom_fields["time_registration_start"] = Time.now.to_i
        post.custom_fields["time_registration_user"] = current_user.id
        post.custom_fields["time_registration_description"] = description
        post.save_custom_fields

        # Set User Custom Field
        current_user.custom_fields["active_time_registration_post_id"] = post.id
        current_user.save_custom_fields

        render json: success_json.merge(active: true, post_id: post.id)
      else
        render_json_error("Could not create post")
      end
    end

    def stop_timer(post_id)
      post = Post.find_by(id: post_id)

      if post
        end_time = Time.now.to_i
        start_time = post.custom_fields["time_registration_start"].to_i
        duration = end_time - start_time

        post.custom_fields["time_registration_end"] = end_time
        post.save_custom_fields

        # Update the raw text to show it is finished
        description = post.custom_fields["time_registration_description"]
        formatted_duration = ActiveSupport::Duration.build(duration).inspect

        new_raw = I18n.t("time_registration.ended_action",
          description: description.presence || I18n.t("time_registration.no_description"),
          duration: formatted_duration
        )

        post.revise(current_user, { raw: new_raw }, { skip_validations: true, bypass_bump: true })
      end

      # Clear User Custom Field
      current_user.custom_fields.delete("active_time_registration_post_id")
      current_user.save_custom_fields

      render json: success_json.merge(active: false)
    end
  end

  DiscourseTimeRegistration::Engine.routes.draw do
    post "/toggle" => "time_tracking#toggle"
  end

  Discourse::Application.routes.append do
    mount ::DiscourseTimeRegistration::Engine, at: "/time-registration"
  end
end

