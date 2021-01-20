class ImportSwaggerService
  def initialize(project:, swagger_content:)
    @project = project
    @swagger_content = swagger_content
  end

  def execute
    @resource_representation_mapper = ResourceRepresentationMapper.new
    @attribute_mapper = AttributeMapper.new
    @route_mapper = RouteMapper.new
    @query_parameters_mapper = QueryParameterMapper.new
    @response_mapper = ResponseMapper.new
    @api_error_mapper = ApiErrorMapper.new
    ActiveRecord::Base.transaction do
      @swagger_content = JSON.parse(@swagger_content)
      create_project_swagger(project_info: @swagger_content['info'])
      create_servers(servers: @swagger_content['servers'])
      create_resources_swagger(resources: @swagger_content['tags'])
      schemas = @swagger_content.dig('components', 'schemas')
      create_resource_representations_swagger(schemas: schemas)
      create_attributes_resource_representation(schemas: schemas)
      create_api_errors_swagger(schemas: schemas)
      create_route_swagger(paths: @swagger_content['paths'], schemas: schemas)
    end
  end

  private

  def create_project_swagger(project_info:)
    @project.title = project_info['title']
    @project.description = project_info['description']
    raise ProjectRecordInvalidError unless @project.save
  end

  def create_servers(servers:)
    server = servers.first
    target_base_url = server['url']
    ProxyConfiguration.create!(project: @project, target_base_url: target_base_url)
  end

  def create_resources_swagger(resources:)
    resources.each do |resource_json|
      new_resource = Resource.create!(
        name: resource_json['name'],
        description: resource_json['description'],
        project: @project
      )
      new_resource.resource_representations.first.destroy!
    end
  end

  def create_resource_representations_swagger(schemas:)
    schemas.keys.each do |representation_name|
      next if representation_name =~ /_|Error/
      new_resource_representation = @resource_representation_mapper.map(
        project: @project,
        rest_resource_representation: schemas[representation_name],
        representation_name: representation_name
      )
      ResourceRepresentationBuilder.new(project: @project,
                                        resource_representation: new_resource_representation,
                                        rest_resource_representation: schemas[representation_name]
      ).build
      new_resource_representation.save!
    end
  end

  def create_attributes_resource_representation(schemas:)
    schemas.keys.each do |representation_name|
      next if representation_name =~ /_|Error/
      current_resource = Resource.find_by(
        name: schemas.dig(representation_name, 'title')&.split(' - ')&.first,
        project: @project
      )
      current_resource_representation = ResourceRepresentation.find_by(
        name: representation_name,
        resource: current_resource
      )

      properties = schemas.dig(representation_name, 'properties')
      properties.each do |property|
        current_attribute = find_or_create_attribute(current_resource: current_resource, property: property)
        attribute_resource_representation_name = (property[1]['$ref'] || property[1].dig('items', '$ref'))&.split('/')&.last
        attribute_resource_representation = ResourceRepresentation.find_by(name: attribute_resource_representation_name)
        required_attributes = schemas.dig(representation_name, 'required')
        attribute_is_required = current_attribute.name.in?(required_attributes)
        AttributesResourceRepresentation.create!(
          parent_resource_representation: current_resource_representation,
          resource_attribute: current_attribute,
          resource_representation: attribute_resource_representation,
          is_required: attribute_is_required
        )
      end
    end
  end

  def find_or_create_attribute(current_resource:, property:)
    new_attribute = @attribute_mapper.map(
      rest_attribute: property,
      parent_resource: current_resource
    )
    Attribute.find_or_create_by!(
      name: new_attribute.name,
      parent_resource: new_attribute.parent_resource
    ) do |attribute|
      new_attribute.attributes.each do |key, value|
        attribute[key] = value
      end
    end
  end

  def create_api_errors_swagger(schemas:)
    schemas.keys.each do |error_name|
      next unless error_name =~ /Error/
      new_api_error = @api_error_mapper.map(
        project: @project,
        rest_api_error: schemas[error_name],
        rest_api_error_name: error_name
      )
      new_api_error.save!
    end
  end

  def create_route_swagger(paths:, schemas:)
    paths.keys.each do |route_url|
      http_methods = paths[route_url]
      http_methods.each do |http_method|
        next if http_method[0] =~ /options/

        current_route = @route_mapper.map(
          route_url: route_url,
          rest_route: http_method,
          project: @project,
          schemas: schemas
        )
        RouteBuilder.new(route: current_route, project: @project).build
        current_route.save!

        route_info = http_method[1]
        parameters = route_info['parameters']
        create_query_parameters(route: current_route, parameters: parameters)
        responses = route_info['responses']
        create_responses_swagger(schemas: schemas, route: current_route, responses: responses)
      end
    end
  end

  def create_query_parameters(route:, parameters:)
    parameters&.each do |parameter|
      @query_parameters_mapper.map(route: route, rest_parameter: parameter).save! if parameter['in'] == 'query'
    end
  end

  def create_responses_swagger(schemas:, route:, responses:)
    responses&.each do |response|
      referenced_representation_name = response.dig(1, 'content', 'application/json', 'schema', '$ref')&.split('/')&.last
      route_additional_infos = schemas[referenced_representation_name]
      if referenced_representation_name&.match?(/Response_|Request_/)
        response_root_key = route_additional_infos&.dig('properties')&.keys&.first
      end
      response_is_collection = route_additional_infos&.dig('properties', response_root_key, 'type') == 'array'
      resource_representation_name = route_additional_infos&.dig('title')&.split(' - ')&.last
      new_response = @response_mapper.map(
        project: @project,
        route: route,
        rest_response: response,
        resource_representation_name: resource_representation_name,
        root_key: response_root_key,
        is_collection: response_is_collection
      )
      new_response.save!
    end
  end
end