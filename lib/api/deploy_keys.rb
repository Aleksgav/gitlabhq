module API
  class DeployKeys < Grape::API
    before { authenticate! }

    get "deploy_keys" do
      authenticated_as_admin!

      keys = DeployKey.all
      present keys, with: Entities::SSHKey
    end

    params do
      requires :id, type: String, desc: 'The ID of the project'
    end
    resource :projects do
      before { authorize_admin_project }

      desc "Get a specific project's deploy keys" do
        success Entities::SSHKey
      end
      get ":id/deploy_keys" do
        present user_project.deploy_keys, with: Entities::SSHKey
      end

      desc 'Get single deploy key' do
        success Entities::SSHKey
      end
      params do
        requires :key_id, type: Integer, desc: 'The ID of the deploy key'
      end
      get ":id/deploy_keys/:key_id" do
        key = user_project.deploy_keys.find params[:key_id]
        present key, with: Entities::SSHKey
      end

      desc 'Add new deploy key to currently authenticated user' do
        success Entities::SSHKey
      end
      params do
        requires :key, type: String, desc: 'The new deploy key'
        requires :title, type: String, desc: 'The name of the deploy key'
      end
      post ":id/deploy_keys" do
        params[:key].strip!

        # Check for an existing key joined to this project
        key = user_project.deploy_keys.find_by(key: params[:key])
        if key
          present key, with: Entities::SSHKey
          break
        end

        # Check for available deploy keys in other projects
        key = current_user.accessible_deploy_keys.find_by(key: params[:key])
        if key
          user_project.deploy_keys << key
          present key, with: Entities::SSHKey
          break
        end

        # Create a new deploy key
        key = DeployKey.new(declared_params(include_missing: false))
        if key.valid? && user_project.deploy_keys << key
          present key, with: Entities::SSHKey
        else
          render_validation_error!(key)
        end
      end

      desc 'Enable a deploy key for a project' do
        detail 'This feature was added in GitLab 8.11'
        success Entities::SSHKey
      end
      params do
        requires :key_id, type: Integer, desc: 'The ID of the deploy key'
      end
      post ":id/deploy_keys/:key_id/enable" do
        key = ::Projects::EnableDeployKeyService.new(user_project,
                                                      current_user, declared_params).execute

        if key
          present key, with: Entities::SSHKey
        else
          not_found!('Deploy Key')
        end
      end

      desc 'Disable a deploy key for a project' do
        detail 'This feature was added in GitLab 8.11'
        success Entities::SSHKey
      end
      params do
        requires :key_id, type: Integer, desc: 'The ID of the deploy key'
      end
      delete ":id/deploy_keys/:key_id/disable" do
        key = user_project.deploy_keys_projects.find_by(deploy_key_id: params[:key_id])
        key.destroy

        present key.deploy_key, with: Entities::SSHKey
      end

      desc 'Delete deploy key for a project' do
        success Key
      end
      params do
        requires :key_id, type: Integer, desc: 'The ID of the deploy key'
      end
      delete ":id/deploy_keys/:key_id" do
        key = user_project.deploy_keys_projects.find_by(deploy_key_id: params[:key_id])
        if key
          key.destroy
        else
          not_found!('Deploy Key')
        end
      end
    end
  end
end
