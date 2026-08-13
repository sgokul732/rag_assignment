class Document < ApplicationRecord
  has_many :chunks, dependent: :destroy
end
