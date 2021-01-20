Rails.application.routes.draw do

  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
  resources :projects do
    collection do
      get 'new_import_swagger'
      post 'import_swagger'
    end
    resources :resources, except: [:edit] do
      member do
        get 'edit_attributes'
        get 'edit_resource'
      end
    end
    resources :routes do
      collection do
        post 'rest'
      end
    end
    resources :security_schemes
    resources :api_errors
    resources :reports, only: [:index, :show] do
      member do
        post 'revalidate'
      end
    end
    resources :mock_profiles, only: [:index, :new, :create]
    resources :metadata, only: [:show, :index, :new, :create]
    match 'mocks', to: "mocks#compute_mock", via: :all, as: 'mocks_root'
    match 'mocks/*path', to: "mocks#compute_mock", via: :all, as: 'mocks'
    resources :mock_profiles, param: :mock_profile_id do
      match 'mocks', to: "mock_profiles#compute_mock", via: :all, as: 'mocks_root', on: :member
      match 'mocks/*path', to: "mock_profiles#compute_mock", via: :all, as: 'mocks', on: :member
    end
    match 'search', to: 'projects#search', via: [:get]
    resources :audits, only: [:index] do
      collection do
        post 'slack_post'
      end
    end
    member do
      get 'slack_oauth2'
    end
  end
  resources :resources, only: [] do
    resources :resource_representations, except: [:index] do
      match 'clone', via: [:post]
      member do
        get 'random'
      end
    end
    resources :resource_instances, only: [:new, :create]
  end
  resources :routes, only: [] do
    resources :responses, except: [:index, :show]
  end
  resources :api_error, only: [] do
    resources :api_error_instances, only: [:new, :create]
  end
  resources :metadata, only: [] do
    resources :metadatum_instances, only: [:new, :create]
  end
  resources :metadata, only: [:edit, :update, :destroy]
  resources :resource_instances, only: [:edit, :update, :destroy]
  resources :api_error_instances, only: [:edit, :update, :destroy]
  resources :metadatum_instances, only: [:edit, :update, :destroy]
  resources :mock_profiles, only: [:edit, :update, :show, :destroy]
  resources :validations, only: [:create, :new, :index]
  resources :instances, only: [:create]
  resources :headers, only: [:index]
  resources :users, only: [:index, :show, :update, :destroy]
  resources :schemes
  root "projects#index"
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
