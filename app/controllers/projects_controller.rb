class ProjectsController < ApplicationController
  lazy_controller_of :project
  decorates_method :project

  def index
    @projects = policy_scope(Project).all.order('lower(title)')
  end

  def show
    respond_to do |format|
      format.html {}
      format.json_schema do
        send_data(
          project.json_schemas_zip_data,
          type: 'application/zip',
          filename: "#{project.title}.json_schema.zip"
        )
      end
      format.swagger do
        swagger = Swagger::ProjectDecorator.new(project).to_swagger(with_api_gateway_integration: params[:with_api_gateway_integration])
        render json: swagger, content_type: 'application/json'
      end
      %i[swift kotlin ruby typescript].each do |language|
        format.send(language) do
          send_data(
            CodeZipBuilder.new(project, language).zip_data,
            type: 'application/zip',
            filename: "#{project.title}.#{language}.zip"
          )
        end
      end
    end
  end

  def new; end

  def new_import_swagger; end

  def import_swagger
    ImportSwaggerService.new(
      project: project,
      swagger_content: params.dig(:import_swagger, :content)
    ).execute
    redirect_to project
  rescue ProjectRecordInvalidError
    render 'new_import_swagger', status: :unprocessable_entity
  end

  def edit
    project.build_proxy_configuration unless project.proxy_configuration
    project.build_api_gateway_integration unless project.api_gateway_integration
  end

  def create
    if project.save
      redirect_to project
    else
      render 'new', status: :unprocessable_entity
    end
  end

  def update
    params = permitted_attributes(project)

    set_proxy_to_be_destroyed_if_blank(params)

    if project.update(params)
      redirect_to project
    else
      render 'edit', status: :unprocessable_entity
    end
  end

  def destroy
    project.destroy

    redirect_to projects_path
  end

  def search
    @results = SearchService.new(project).search(params[:query])
  end

  def slack_oauth2
    if SetSlackWebhook.new(project).execute(params[:code], slack_oauth2_project_url(project))
      redirect_to project
    else
      redirect_to project, alert: 'Slack integration failed'
    end
  end

  private

  def set_proxy_to_be_destroyed_if_blank(params)
    proxy_config = params.dig(:proxy_configuration_attributes)
    return if proxy_config.nil? || proxy_config.dig(:target_base_url).present?

    params[:proxy_configuration_attributes] = {
      id: project.proxy_configuration&.id,
      _destroy: true
    }
  end
end
