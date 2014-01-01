Blog::Application.routes.draw do
  devise_for :users

  get '/ui/(:action)', controller: :ui if Rails.env.development?
  get '/sitemap.xml', to: 'sitemap#index',   as: :sitemap, defaults: { format: :xml }
  get '/dashboard',   to: 'dashboard#index', as: :dashboard
  get '/:id',         to: 'posts#show',      as: :post

  root to: 'posts#index'
end
