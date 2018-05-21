module QA
  module Page
    module Project
      module Operations
        module Kubernetes
          class Add < Page::Base
            view 'app/views/projects/clusters/new' do
              element :add_kubernetes_cluster_button, 'link_to _("Add an existing Kubernetes cluster")'
            end

            def add_existing_cluster
              click_on 'Add an existing Kubernetes cluster'
            end
          end
        end
      end
    end
  end
end
