Rails.application.routes.draw do

  resources :projects do
    resources :json_schemas
    resources :resources do
      resources :routes, except: [:index]
      resources :attributes, only: [:destroy]
    end
  end
  match "/not_found", to: "errors#not_found", via: :all
  root "projects#index"
  match '*path', to: "errors#not_found", via: :all
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
