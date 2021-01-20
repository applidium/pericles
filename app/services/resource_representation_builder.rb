class ResourceRepresentationBuilder
  def initialize(project:, resource_representation:, rest_resource_representation:)
    @project = project
    @resource_representation = resource_representation
    @rest_resource_representation = rest_resource_representation
  end

  def build
    if @resource_representation.resource.nil?
      resource_name = @rest_resource_representation['title']&.split(' - ')&.dig(0)
      parent_resource = Resource.create!(name: resource_name, project: @project)
      parent_resource.resource_representations.first.destroy!
      @resource_representation.resource = parent_resource
    end
  end
end