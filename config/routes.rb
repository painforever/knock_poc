Rails.application.routes.draw do
  root to: 'home#index'
  get 'home/index'

  #TODO will be removed since it's just a form for inserting fake data
  match 'home/upload_essay_form', via: [:get, :post]

  devise_for :users, controllers: {
      sessions: 'users/sessions',
      registrations: 'users/registrations'
  }

  resources :users, only: [:show, :index]
  resources :meetings, except: [:destroy]

end
