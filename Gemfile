source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.0.1'
# Use postgresql as the database for Active Record
gem 'pg', '~> 0.18'
# Use Puma as the app server
gem 'puma', '~> 3.0'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# ****************************************
# rails api                             *
gem 'grape' #
# create grape document                 *
gem 'grape-swagger' #
# create swagger router                 *
gem 'grape-swagger-rails' #
# => disables the security feature of   *
# => strong_params at the model         *
gem 'hashie-forbidden_attributes' #
# ****************************************

# ****************************************
# => using for login                    *
gem 'devise_token_auth' #
# => using for authenticate             *
gem 'omniauth' #
# => using for get JSON  whren your API *
# => and client on different domain     *
gem 'rack-cors', require: 'rack/cors' #
# ****************************************

# ****************************************
# fake model data for test              *
gem 'factory_girl_rails' #
# generate fake date                    *
gem 'faker' #
# ****************************************

gem 'active_model_serializers'
gem 'grape-active_model_serializers'
gem 'rails_best_practices'

gem 'clockwork'
gem 'sidekiq'
gem 'premailer-rails'
gem 'nokogiri'

# => generate diagram
gem "rails-erd"
gem 'ruby-graphviz', '~> 1.2', '>= 1.2.2'
# => end generate diagram

gem 'rubyzip'
gem 'wkhtmltopdf-binary'
gem 'wicked_pdf'
 gem 'redis', '~>3.2'

# Using config global variable
gem 'config'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'rspec-rails'
  gem 'rspec-collection_matchers'
  gem 'shoulda-matchers', '~> 3.1'
  gem 'email_spec'
  gem 'pry-byebug'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '~> 3.0.5'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'letter_opener'
  gem 'letter_opener_web'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
ruby '2.3.1'
