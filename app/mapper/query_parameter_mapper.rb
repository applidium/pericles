class QueryParameterMapper
  def map(route:, rest_parameter:)
    QueryParameter.new(
      name: rest_parameter['name'],
      is_optional: !rest_parameter['required'],
      primitive_type: rest_parameter.dig('schema', 'type'),
      route: route
    )
  end
end