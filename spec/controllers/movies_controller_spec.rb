require 'rails_helper'

describe MoviesController, type: :controller do
  describe 'searching TMDb' do
    before :each do
      @fake_results = [double('movie1'), double('movie2')]
    end
    it 'calls the model method that performs TMDb search' do
      expect(Movie).to receive(:find_in_tmdb).with(hash_including(title: 'hardware')).
        and_return(@fake_results)
      get :search_tmdb, params: { title: 'hardware' }
    end
    describe 'after valid search' do
      before :each do
        allow(Movie).to receive(:find_in_tmdb).and_return(@fake_results)
        get :search_tmdb, params: { title: 'hardware' }
      end
      it 'selects the Search Results template for rendering' do
        expect(response).to render_template('search_tmdb')
      end
      it 'makes the TMDb search results available to that template' do
        expect(assigns(:movies)).to eq(@fake_results)
      end
    end
    describe 'when first visiting the search page' do
      it 'does not call TMDb or show an error' do
        expect(Movie).not_to receive(:find_in_tmdb)
        get :search_tmdb
        expect(flash[:danger]).to be_nil
        expect(response).to render_template('search_tmdb')
      end
    end
    describe 'when the title is missing' do
      before :each do
        expect(Movie).not_to receive(:find_in_tmdb)
        get :search_tmdb, params: { title: '', release_year: '2000' }
      end
      it 'shows an error message' do
        expect(flash[:danger]).to eq('Please fill in all required fields!')
      end
      it 'does not make any search results available' do
        expect(assigns(:movies)).to be_nil
      end
    end
    describe 'when no movies match' do
      it 'shows a no-results message' do
        allow(Movie).to receive(:find_in_tmdb).and_return([])
        get :search_tmdb, params: { title: 'qwertyuiop' }
        expect(flash[:warning]).to eq('No movies found with given parameters!')
      end
    end
  end

  describe 'adding a movie from TMDb' do
    let(:movie_params) do
      { title: 'Manhunter', release_date: '1986-08-15', rating: 'R', description: 'A thriller.' }
    end
    it 'saves the movie to the database' do
      expect { post :add_movie, params: movie_params }.to change(Movie, :count).by(1)
      expect(Movie.last.title).to eq('Manhunter')
    end
    it 'redirects to the search page' do
      post :add_movie, params: movie_params
      expect(response).to redirect_to(search_tmdb_path)
    end
    it 'shows a success message' do
      post :add_movie, params: movie_params
      expect(flash[:success]).to eq('Manhunter was successfully added to RottenPotatoes.')
    end
  end
end