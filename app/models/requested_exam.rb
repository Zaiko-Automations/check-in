class RequestedExam < ApplicationRecord
  belongs_to :walk_in
  validates :descricao, presence: true
end
