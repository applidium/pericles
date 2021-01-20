class ApiErrorMapper
  def map(project:, rest_api_error:, rest_api_error_name:)
    ApiError.new(
      project: project,
      name: rest_api_error_name,
      json_schema: JSON(rest_api_error)
    )
  end
end