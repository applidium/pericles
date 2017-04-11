class Response < ApplicationRecord
  belongs_to :route, inverse_of: :responses

  has_many :headers, as: :http_message, dependent: :destroy

  accepts_nested_attributes_for :headers, allow_destroy: true, reject_if: :all_blank

  validates :status_code, presence: true
  validates :body_schema, json_schema: true, allow_blank: true
  validates :route, presence: true
end