class AttributeMapper
  def map(rest_attribute:, parent_resource:)
    name = rest_attribute[0]
    attributes_info = rest_attribute[1]

    if attributes_info['$ref']
      attributes = get_attribute_fields(:ref, attributes_info, parent_resource)
    elsif attributes_info['type']
      if attributes_info['type'] == 'array'
        attributes = get_attribute_fields(:array, attributes_info, parent_resource)
      else
        attributes = get_attribute_fields(:primitive_type, attributes_info, parent_resource)
      end
    end

    refactor_attributes_keys(attributes: attributes, missing_fields: attributes_info)
    Attribute.new(
      {
        name: name,
        parent_resource: parent_resource
      }.merge(attributes)
    )
  end

  private

  def hash_keys_to_snake_case(hash)
    hash.transform_keys { |k| k.to_s.underscore.to_sym }
  end

  def keys_from_swagger_to_pericles!(hash)
    valid_keys = { min_length: 'minimum', max_length: 'maximum' }
    hash.transform_keys! { |k| valid_keys[k] || k }
  end

  def get_resource_from_representation_name(name, project)
    resource_representations = ResourceRepresentation.where(name: name).select do |resource_representation|
      resource_representation.project == project
    end
    resource_representations&.first&.resource
  end

  def get_attribute_fields(attribute_type, attributes_info, parent_resource)
    attributes = {}
    case attribute_type
    when :ref
      resource_representation_name = attributes_info['$ref'].split('/').last
      attributes[:resource] = get_resource_from_representation_name(resource_representation_name, parent_resource.project)
    when :array
      attributes[:is_array] = true
      resource_representation_name = attributes_info.dig('items', '$ref')&.split('/')&.last
      primitive_type = attributes_info.dig('items', 'type')
      attributes[:primitive_type] = Attribute.primitive_types[primitive_type]
      attributes[:resource] = get_resource_from_representation_name(resource_representation_name, parent_resource.project) unless primitive_type
    when :primitive_type
      attributes[:primitive_type] = Attribute.primitive_types[attributes_info['type']]
    end
    attributes
  end

  def refactor_attributes_keys(attributes:, missing_fields:)
    attributes.merge!(hash_keys_to_snake_case(missing_fields))
    keys_from_swagger_to_pericles!(attributes)
    attributes.reject! { |k, _| k.in? %i[type format items pattern $ref] }
  end
end