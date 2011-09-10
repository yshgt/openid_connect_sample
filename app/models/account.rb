class Account < ActiveRecord::Base
  has_one :facebook, class_name: 'Connect::Facebook'
  has_one :google,   class_name: 'Connect::Google'
  has_one :fake,     class_name: 'Connect::Fake'
  has_many :clients
  has_many :access_tokens
  has_many :authorizations
  has_many :id_tokens
  has_many :pairwise_pseudonymous_identifiers

  before_validation :setup, on: :create

  validates :identifier, presence: true, uniqueness: true

  def to_response_object(access_token)
    user_info = (google || facebook || fake).user_info
    user_info.id = if access_token.accessible?(Scope::PPID)
      pairwise_pseudonymous_identifiers.find_or_create_by_client_id(access_token.client_id).identifier
    else
      identifier
    end
    user_info.profile = nil unless access_token.accessible?(Scope::PROFILE)
    user_info.email   = nil unless access_token.accessible?(Scope::EMAIL)
    user_info.address = nil unless access_token.accessible?(Scope::ADDRESS)
    user_info
  end

  private

  def setup
    self.identifier = SecureRandom.hex(8)
  end
end