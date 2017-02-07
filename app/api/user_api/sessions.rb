module UserApi
  class Sessions < Grape::API
    prefix  :api
    version 'v1', using: :accept_version_header

    helpers do
      def sign_in_params
        user_params = params['user']
        User.find_by(email: user_params['email'])
      end

      def sign_in_token_validation
        data  = @resource.token_validation_response.to_h
        data.store('client', @client_id)
        data.store('token', @token)
        data
      end

      def return_message status, data = nil
        {
          status: status,
          data: data
        }
      end
    end

    resource :users do
      # => /api/v1/users/
      desc "sign-in" #, entity: Entities::ProductWithRoot
      params do
        requires :user, type: Hash do
          requires :email, type: String, desc: "User's Email"
          requires :password,  type: String, desc: "password"
        end
      end
      post '/sign-in' do
        @resource = sign_in_params
        if @resource and @resource.valid_password?(params['user']['password']) and (!@resource.respond_to?(:active_for_authentication?) or @resource.active_for_authentication?)
          # create client id
          @client_id = SecureRandom.urlsafe_base64(nil, false)
          @token     = SecureRandom.urlsafe_base64(nil, false)

          @resource.tokens[@client_id] = {
            token: BCrypt::Password.create(@token),
            expiry: (Time.now + DeviseTokenAuth.token_lifespan).to_i
          }
          @resource.save
          return_message 'Create Success', sign_in_token_validation
        elsif @resource and not (!@resource.respond_to?(:active_for_authentication?) or @resource.active_for_authentication?)
          error!(I18n.t("devise_token_auth.sessions.not_confirmed", email: @resource.email), 500)
        else
          error!(I18n.t("devise_token_auth.sessions.bad_credentials"), 500)
        end
      end

      desc "sign-out" #, entity: Entities::ProductWithRoot
      params do
        requires :auth, type: Hash do
          requires :uid, type: String, desc: "uid"
          requires :client,  type: String, desc: "client"
          requires :access_token,  type: String, desc: "access-token"
        end
      end
      post '/sign-out' do
        @resource = User.find_by(email: params['auth']['uid'])
        @client_id = params['auth']['client']
        @token = params['auth']['access_token']

        user = remove_instance_variable(:@resource) if @resource
        client_id = remove_instance_variable(:@client_id) if @client_id
        remove_instance_variable(:@token) if @token

        if user and client_id and user.tokens[client_id]
          user.tokens.delete(client_id)
          user.save!
          return_message 'Logout Success'
        else
          error!(I18n.t("devise_token_auth.sessions.user_not_found"), 404)
        end
      end
    end
  end
end
