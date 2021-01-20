class ResourceRepresentationMapper
  def map(project:, rest_resource_representation:, representation_name:)
    resource_name = rest_resource_representation['title']&.split(' - ')&.dig(0)
    parent_resource = Resource.find_by(name: resource_name, project: project)
    ResourceRepresentation.new(name: representation_name, resource: parent_resource)
  end
end