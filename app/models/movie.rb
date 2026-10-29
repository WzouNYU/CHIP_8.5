class Movie < ApplicationRecord
  TMDB_SEARCH_URL = 'https://api.themoviedb.org/3/search/movie'.freeze

  def self.all_ratings
    %w[G PG PG-13 R]
  end

  def self.with_ratings(ratings, sort_by)
    if ratings.nil?
      all.order sort_by
    else
      where(rating: ratings.map(&:upcase)).order sort_by
    end
  end

  # Searches TMDb and returns an array of Movie objects that are NOT saved
  # to the database. search_params is a hash with :title (required),
  # :release_year (optional) and :language ('en' or 'all').
  # The API key defaults to the TMDB_API_KEY environment variable, but can be
  # overridden (e.g. with an invalid key) for testing.
  def self.find_in_tmdb(search_params, api_key = ENV['TMDB_API_KEY'])
    response = Faraday.get(tmdb_search_url(search_params, api_key))
    return [] unless response && response.status == 200

    results = JSON.parse(response.body)['results'] || []
    movies = results.map do |result|
      Movie.new(
        title: result['title'],
        release_date: result['release_date'],
        rating: 'R', # TMDb search doesn't return MPAA ratings, so default to R
        description: result['overview']
      )
    end
    # Leave out movies that have already been added to RottenPotatoes
    movies.reject { |movie| Movie.exists?(title: movie.title, release_date: movie.release_date) }
  end

  def self.tmdb_search_url(search_params, api_key)
    query = { api_key: api_key, query: search_params[:title] }
    query[:year] = search_params[:release_year] if search_params[:release_year].present?
    query[:language] = 'en-US' if search_params[:language] == 'en'
    "#{TMDB_SEARCH_URL}?#{URI.encode_www_form(query)}"
  end
  private_class_method :tmdb_search_url
end