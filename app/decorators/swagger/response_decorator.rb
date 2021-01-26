class Swagger::ResponseDecorator < Draper::Decorator
  delegate_all

  def to_swagger
    h = { description: '' }
    return h unless json_schema(context: context)

    h.merge(
      {
        content: {
          'application/json' => {
            schema: {
              '$ref' => ref
            }
          }
        }
      }
    )
  end

  def uid
    if context[:use_resource_representation_name_as_uid] && plain_representation? && representation&.name
      representation.name.tr(' ', '_')
    else
      "Response_#{object.id}"
    end
  end

  def ref
    "#{base_href}#{uid}"
  end

  def base_href
    # TODO: Clément Villain 2/03/18 refactor with json schema
    context[:base_href] || '#/definitions/'
  end
end
