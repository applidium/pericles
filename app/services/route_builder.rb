class RouteBuilder
  def initialize(route:, project:)
    @route = route
    @project = project
  end

  def build
    @route.resource = Resource.find_or_create_by(name: 'Unknown', project: @project) if @route.resource.nil?
  end
end