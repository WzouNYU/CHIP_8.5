require 'rails_helper'
require 'spec_helper'

describe Movie do
  describe 'searching TMDB by keyword' do
    before :each do
      olympics_results = {
        page: 1,
        results: [
          { id: 716088, original_language: 'en', title: 'Sydney 2000 Olympics Opening Ceremony',
            overview: 'Coverage of the Olympic Opening Ceremony of the Games in Sydney.',
            release_date: '2000-09-15' },
          { id: 716098, original_language: 'en', title: 'Sydney 2000 Olympics Closing Ceremony',
            overview: 'The 2000 Summer Olympics Closing Ceremony.',
            release_date: '2000-10-01' }
        ],
        total_pages: 1,
        total_results: 2
      }
      stub_request(:get, /api.themoviedb.org/).
        to_return(status: 200, body: JSON.generate(olympics_results), headers: {})
    end

    it 'calls Faraday gem' do
      expect(Faraday).to receive(:get).and_call_original
      Movie.find_in_tmdb({ title: 'Olympics', release_year: '2000', language: 'all' })
    end
    it 'calls TMDb with valid API key' do
      Movie.find_in_tmdb({ title: 'hacker', language: 'en' })
    end
    it 'sends the title, year and language to TMDb' do
      Movie.find_in_tmdb({ title: 'Manhunter', release_year: '1986', language: 'en' })
      expect(WebMock).to have_requested(:get, /api.themoviedb.org/).
        with(query: hash_including('query' => 'Manhunter', 'year' => '1986', 'language' => 'en-US'))
    end
    it 'leaves out the year when it is blank' do
      Movie.find_in_tmdb({ title: 'Manhunter', release_year: '', language: 'all' })
      expect(WebMock).to have_requested(:get, /api.themoviedb.org/).
        with { |req| !req.uri.query.include?('year=') }
    end
    it 'returns unsaved Movie objects built from the results' do
      movies = Movie.find_in_tmdb({ title: 'Olympics', release_year: '2000' })
      expect(movies.length).to eq(2)
      expect(movies).to all(be_a(Movie))
      expect(movies).to all(be_new_record)
      expect(movies.first.title).to eq('Sydney 2000 Olympics Opening Ceremony')
      expect(movies.first.release_date).to eq(Date.new(2000, 9, 15))
    end
    it 'gives every movie an R rating' do
      movies = Movie.find_in_tmdb({ title: 'Olympics' })
      expect(movies.map(&:rating)).to all(eq('R'))
    end
    it 'leaves out movies that are already in the database' do
      Movie.create!(title: 'Sydney 2000 Olympics Opening Ceremony', release_date: '2000-09-15', rating: 'R')
      movies = Movie.find_in_tmdb({ title: 'Olympics', release_year: '2000' })
      expect(movies.map(&:title)).to eq(['Sydney 2000 Olympics Closing Ceremony'])
    end
    it 'returns an empty list when nothing matches' do
      stub_request(:get, /api.themoviedb.org/).
        to_return(status: 200, body: JSON.generate({ page: 1, results: [], total_pages: 0, total_results: 0 }))
      expect(Movie.find_in_tmdb({ title: 'qwertyuiop' })).to eq([])
    end
    it 'returns an empty list when the API key is invalid' do
      stub_request(:get, /api.themoviedb.org/).
        to_return(status: 401, body: JSON.generate({ status_code: 7, status_message: 'Invalid API key' }))
      expect(Movie.find_in_tmdb({ title: 'Manhunter' }, 'invalid_key')).to eq([])
    end
  end
end