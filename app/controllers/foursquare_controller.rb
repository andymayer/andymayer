# Connects to Foursquare via API
class FoursquareController < ApplicationController

  def callback
    if FOURSQUARE_OAUTH_TOKEN.blank?
      uri                    = URI.parse('https://foursquare.com/oauth2/access_token'\
                                         "?client_id=#{FOURSQUARE_CLIENT_ID}"\
                                         "&client_secret=#{FOURSQUARE_CLIENT_SECRET}"\
                                         '&grant_type=authorization_code'\
                                         "&redirect_uri=#{FOURSQUARE_CALLBACK_URL}"\
                                         "&code=#{params[:code]}")
      http                   = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl           = true
      http.verify_mode       = OpenSSL::SSL::VERIFY_NONE
      request                = Net::HTTP::Get.new(uri.request_uri)
      response               = JSON.parse(http.request(request).body)
      client                 = OAuth2::Client.new(FOURSQUARE_CLIENT_ID,
                                                  FOURSQUARE_CLIENT_SECRET,
                                                  site: 'http://foursquare.com/oauth2/',
                                                  request_token_path: '/oauth2/request_token',
                                                  access_token_path: '/oauth2/access_token',
                                                  authorize_path: '/oauth2/authenticate?response_type=code',
                                                  parse_json: true)
      access_token           = OAuth2::AccessToken.new(client, response['access_token'])
      session[:access_token] = access_token.token
    else
      redirect_to foursquare_url
    end
  end

  def connect
    if FOURSQUARE_OAUTH_TOKEN.blank?
      redirect_to 'http://foursquare.com/oauth2/authenticate'\
                  "?client_id=#{FOURSQUARE_CLIENT_ID}"\
                  '&response_type=code'\
                  "&redirect_uri=#{FOURSQUARE_CALLBACK_URL}/"
    else
      redirect_to foursquare_url
    end
  end

  def index
    @foursquare_badges      = Rails.cache.fetch('foursquare_badges', expires_in: 12.hours, race_condition_ttl: 10) do
      foursquare_connection = Foursquare2::Client.new(client_id: FOURSQUARE_CLIENT_ID,
                                                      client_secret: FOURSQUARE_CLIENT_SECRET,
                                                      oauth_token: FOURSQUARE_OAUTH_TOKEN) unless foursquare_connection
      foursquare_connection.user_badges('self')
    end
    @foursquare_mayorships  = Rails.cache.fetch('foursquare_mayorships', expires_in: 12.hours, race_condition_ttl: 10) do
      foursquare_connection = Foursquare2::Client.new(client_id: FOURSQUARE_CLIENT_ID,
                                                      client_secret: FOURSQUARE_CLIENT_SECRET,
                                                      oauth_token: FOURSQUARE_OAUTH_TOKEN) unless foursquare_connection
      foursquare_connection.user_mayorships('self')
    end
    @foursquare_tips        = Rails.cache.fetch('foursquare_tips', expires_in: 12.hours, race_condition_ttl: 10) do
      foursquare_connection = Foursquare2::Client.new(client_id: FOURSQUARE_CLIENT_ID,
                                                      client_secret: FOURSQUARE_CLIENT_SECRET,
                                                      oauth_token: FOURSQUARE_OAUTH_TOKEN) unless foursquare_connection
      foursquare_connection.user_tips('self')
    end
  end

end
