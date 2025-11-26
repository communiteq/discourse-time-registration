# name: discourse-time-registration
# about: Time Registration for Discourse
# version: 1.0
# authors: Communiteq

enabled_site_setting :time_registration_enabled

register_asset "stylesheets/common.scss"

register_svg_icon "stopwatch" if respond_to?(:register_svg_icon)
register_svg_icon "rotate-left" if respond_to?(:register_svg_icon)

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
  User.register_custom_field_type "active_time_registration_description", :string
  User.register_custom_field_type "active_time_registration_start", :integer

  # Whitelist fields for serialization so the frontend can see them
  DiscoursePluginRegistry.serialized_current_user_fields << "active_time_registration_post_id"
  DiscoursePluginRegistry.serialized_current_user_fields << "active_time_registration_description"
  DiscoursePluginRegistry.serialized_current_user_fields << "active_time_registration_start"

  # Register Post Custom Fields
  Post.register_custom_field_type "time_registration_start", :integer
  Post.register_custom_field_type "time_registration_amount", :integer
  Post.register_custom_field_type "time_registration_user", :integer
  Post.register_custom_field_type "time_registration_description", :string

  # Add fields to PostSerializer so they are available in the JSON
  add_to_serializer(:post, :time_registration_start) { object.custom_fields["time_registration_start"] }
  add_to_serializer(:post, :time_registration_amount) { object.custom_fields["time_registration_amount"] }
  add_to_serializer(:post, :time_registration_user) { object.custom_fields["time_registration_user"] }
  add_to_serializer(:post, :time_registration_description) { object.custom_fields["time_registration_description"] }

  require_dependency "application_controller"

  class DiscourseTimeRegistration::TimeTrackingController < ::ApplicationController
    requires_plugin DiscourseTimeRegistration::PLUGIN_NAME

    before_action :ensure_logged_in
    before_action :ensure_can_track_time, only: [:toggle]

    def toggle
      active_post_id = current_user.custom_fields["active_time_registration_post_id"]

      # If we have params for manual entry, handle that
      if params[:manual_entry] == "true"
        create_manual_entry
        return
      end

      if active_post_id.present?
        stop_timer(active_post_id)
      else
        start_timer
      end
    end

    def update
      post_id = params.require(:post_id)
      description = params[:description]
      duration_minutes = params[:duration].to_i

      post = Post.find_by(id: post_id)
      raise Discourse::NotFound unless post

      # Allow Admin or the Author to edit
      unless current_user.admin? || current_user.id == post.user_id
        raise Discourse::InvalidAccess
      end

      duration_seconds = duration_minutes * 60

      post.custom_fields["time_registration_description"] = description
      post.custom_fields["time_registration_amount"] = duration_seconds
      post.save_custom_fields

      # Update the raw text for fallback/search
      new_raw = I18n.t("time_registration.ended_action",
        description: description.presence || I18n.t("time_registration.no_description"),
        duration: format_duration(duration_seconds)
      )

      post.revise(current_user, { raw: new_raw }, { skip_validations: true, bypass_bump: true })

      # Publish the change to MessageBus
      MessageBus.publish("/topic/#{post.topic_id}", {
        id: post.id,
        post_number: post.post_number,
        updated_at: post.updated_at,
        user_id: post.user_id,
        last_editor_id: post.last_editor_id,
        type: "revised",
        version: post.version
      })

      render json: success_json
    end

    def report_data
      from_date = params[:from]
      to_date = params[:to]
      category_id = params[:category_id]
      username = params[:username]

      # Base query: Time registration posts
      query = Post.where(action_code: "time_registration")
                  .joins(:topic)
                  .includes(:user, topic: :category)
                  .preload(:_custom_fields)

      # Security: Only show topics the user can see
      query = query.merge(Topic.secured(guardian))

      # Filters
      if from_date.present?
        query = query.where("posts.created_at >= ?", Date.parse(from_date))
      end

      if to_date.present?
        query = query.where("posts.created_at <= ?", Date.parse(to_date).end_of_day)
      end

      if category_id.present?
        query = query.where(topics: { category_id: category_id })
      end

      if username.present?
        user = User.find_by(username: username)
        if user
          query = query.where(user_id: user.id)
        else
          return render json: { report: [] }
        end
      end

      # Order by newest first
      query = query.order("posts.created_at DESC").limit(500)

      report = query.map do |p|
        amount = p.custom_fields["time_registration_amount"].to_i
        next if amount <= 0 # Skip if no time logged (e.g. just started)

        category_name = if p.topic.private_message?
                          I18n.t("time_registration.report.personal_message")
                        elsif p.topic.category
                          p.topic.category.name
                        else
                          I18n.t("uncategorized")
                        end

        {
          id: p.id,
          post_number: p.post_number,
          topic_id: p.topic_id,
          topic_title: p.topic.title,
          category_name: category_name,
          username: p.user&.username,
          description: p.custom_fields["time_registration_description"] || I18n.t("time_registration.no_description"),
          duration_seconds: amount,
          created_at: p.created_at
        }
      end.compact

      render json: { report: report }
    end

    private

    def ensure_can_track_time
      return if current_user.admin?

      allowed_groups = SiteSetting.time_registration_groups.split("|").map(&:to_i)
      unless current_user.groups.where(id: allowed_groups).exists?
        raise Discourse::InvalidAccess.new("You are not in a time registration group")
      end
    end

    def create_manual_entry
      topic_id = params.require(:topic_id)
      description = params[:description]
      duration_minutes = params[:duration].to_i

      topic = Topic.find_by(id: topic_id)
      raise Discourse::NotFound unless topic

      duration_seconds = duration_minutes * 60

      post = PostCreator.create!(
        current_user,
        topic_id: topic.id,
        post_type: Post.types[:small_action],
        action_code: "time_registration",
        raw: I18n.t("time_registration.manual_entry_action",
          description: description.presence || I18n.t("time_registration.no_description"),
          duration: format_duration(duration_seconds)
        ),
        skip_validations: true
      )

      if post
        post.custom_fields["time_registration_user"] = current_user.id
        post.custom_fields["time_registration_description"] = description
        post.custom_fields["time_registration_amount"] = duration_seconds
        post.save_custom_fields

        render json: success_json
      else
        render_json_error("Could not create post")
      end
    end

    def start_timer
      topic_id = params.require(:topic_id)
      description = params[:description]

      topic = Topic.find_by(id: topic_id)
      raise Discourse::NotFound unless topic

      post = PostCreator.create!(
        current_user,
        topic_id: topic.id,
        post_type: Post.types[:small_action],
        action_code: "time_registration",
        raw: I18n.t("time_registration.started_action", description: description.presence || I18n.t("time_registration.no_description")),
        skip_validations: true
      )

      if post
        post.custom_fields["time_registration_start"] = Time.now.to_i
        post.custom_fields["time_registration_user"] = current_user.id
        post.custom_fields["time_registration_description"] = description
        post.save_custom_fields

        current_user.custom_fields["active_time_registration_post_id"] = post.id
        current_user.custom_fields["active_time_registration_description"] = description
        current_user.custom_fields["active_time_registration_start"] = post.custom_fields["time_registration_start"]
        current_user.save_custom_fields

        render json: success_json.merge(active: true, post_id: post.id, start_time: post.custom_fields["time_registration_start"])
      else
        render_json_error("Could not create post")
      end
    end

    def stop_timer(post_id)
      post = Post.find_by(id: post_id)

      if post
        # If user provided specific duration/description in stop modal
        description = params[:description] || post.custom_fields["time_registration_description"]

        if params[:duration].present?
          # User overrode the time
          duration_seconds = [params[:duration].to_i, 1].max * 60
        else
          # Calculate from stopwatch
          start_time = post.custom_fields["time_registration_start"].to_i
          raw_duration = Time.now.to_i - start_time
          duration_seconds = apply_rounding(raw_duration)
        end

        post.custom_fields["time_registration_amount"] = duration_seconds
        post.custom_fields["time_registration_description"] = description
        post.custom_fields.delete("time_registration_start")
        post.save_custom_fields

        new_raw = I18n.t("time_registration.ended_action",
          description: description.presence || I18n.t("time_registration.no_description"),
          duration: format_duration(duration_seconds)
        )

        post.revise(current_user, { raw: new_raw }, { skip_validations: true, bypass_bump: true })
      end

      current_user.custom_fields.delete("active_time_registration_post_id")
      current_user.custom_fields.delete("active_time_registration_description")
      current_user.custom_fields.delete("active_time_registration_start")
      current_user.save_custom_fields

      render json: success_json.merge(active: false)
    end

    def apply_rounding(seconds)
      minutes = (seconds / 60.0)
      interval = SiteSetting.time_registration_rounding_interval.to_i
      round_up_at = SiteSetting.time_registration_round_up_at.to_i

      return seconds if interval <= 0

      base = (minutes / interval).floor * interval
      remainder = minutes % interval

      final_minutes = remainder >= round_up_at ? base + interval : base

      # Ensure at least interval
      final_minutes = [final_minutes, interval].max
      (final_minutes * 60).to_i
    end

    def format_duration(seconds)
      hours = seconds / 3600
      minutes = (seconds % 3600) / 60
      "%02d:%02d" % [hours, minutes]
    end
  end

  DiscourseTimeRegistration::Engine.routes.draw do
    post "/toggle" => "time_tracking#toggle"
    put "/update" => "time_tracking#update"
    get "/report" => "time_tracking#report_data"
  end

  Discourse::Application.routes.append do
    mount ::DiscourseTimeRegistration::Engine, at: "/time-registration"
  end
end

