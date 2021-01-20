class RouteMapper
  def map(route_url:, rest_route:, project:, schemas:)
    http_method = rest_route[0]
    route_info = rest_route[1]

    parameters = route_info['parameters']
    route_url = refactor_variables_in_path(parameters: parameters, route_url: route_url)
    request_resource_representation = get_request_resource_representation(route_info: route_info, schemas: schemas, project: project)
    request_root_key = get_request_root_key(route_info: route_info, schemas: schemas)
    resource = Resource.find_by(name: route_info['tags']&.first, project: project)

    Route.new(
      http_method: Route.http_methods[http_method.upcase],
      url: route_url,
      resource: resource,
      description: route_info['description'],
      operation_id: route_info['operationId'],
      request_resource_representation: request_resource_representation,
      request_root_key: request_root_key
    )
  end

  private

  def refactor_variables_in_path(parameters:, route_url:)
    parameters&.each do |parameter|
      route_url = route_url.gsub(Regexp.new("{#{parameter['name']}}"), ":#{parameter['name']}") if parameter['in'] == 'path'
    end
    route_url
  end

  def get_request_resource_representation(route_info:, schemas:, project:)
    request_resource_representation_name = route_info.dig('requestBody', 'content', 'application/json', 'schema', '$ref')&.split('/')&.last
    if request_resource_representation_name&.match?(/Request_/)
      request_resource_representation_name = schemas.dig(request_resource_representation_name, 'title')&.split(' - ')&.last
    end

    ResourceRepresentation.where(name: request_resource_representation_name).select do |resource_representation|
      resource_representation.project == project
    end&.first
  end

  def get_request_root_key(route_info:, schemas:)
    request_resource_representation_name = route_info.dig('requestBody', 'content', 'application/json', 'schema', '$ref')&.split('/')&.last
    if request_resource_representation_name&.match?(/Request_/)
      schemas.dig(request_resource_representation_name, 'properties')&.keys&.first
    end
  end
end
