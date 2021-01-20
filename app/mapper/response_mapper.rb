class ResponseMapper
  def map(project:, route:, rest_response:, resource_representation_name:, root_key:, is_collection:)
    status_code = rest_response[0]
    response_info = rest_response[1]

    resource_representation_name ||= response_info.dig('content', 'application/json', 'schema', '$ref')&.split('/')&.last
    if resource_representation_name
      if status_code.to_i < 400
        resource_representation = ResourceRepresentation.where(name: resource_representation_name).select { |representation|
          representation.project == project
        }&.first
      else
        api_error = ApiError.find_by(project: project, name: resource_representation_name)
      end
    end

    Response.new(
      status_code: status_code,
      route: route,
      resource_representation: resource_representation,
      api_error: api_error,
      root_key: root_key,
      is_collection: is_collection
    )
  end
end