Rails.application.routes.draw do
  mount_devise_token_auth_for 'User', at: 'auth'
  root 'welcome#index'
  post "test", to: "welcome#test"
end
