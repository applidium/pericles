class ProjectPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.where(is_public: true) if user.nil?
      user.internal? ? scope.all : scope.left_joins(:members).where('members.user_id = ? OR projects.is_public = true', user.id)
    end
  end

  def index?
    true
  end

  def new_import_swagger?
    import_swagger?
  end

  def import_swagger?
    create?
  end

  def create?
    user&.internal?
  end

  def update?
    user && show? && (user.internal? || Project.of_user(user).where(id: record.id).exists?)
  end

  def destroy?
    update?
  end

  def search?
    show?
  end

  def slack_oauth2?
    show?
  end

  def slack_post?
    show?
  end

  def permitted_attributes
    [
      :title,
      :description,
      :mock_profile_id,
      :slack_channel,
      :slack_incoming_webhook_url,
      proxy_configuration_attributes: [
        :id,
        :target_base_url,
        :proxy_hostname,
        :proxy_port,
        :proxy_username,
        :proxy_password,
        :ignore_ssl,
        :_destroy
      ],
      api_gateway_integration_attributes: [
        :id,
        :title,
        :uri_prefix,
        :timeout_in_millis,
        :_destroy
      ],
      user_ids: []
    ]
  end
end
