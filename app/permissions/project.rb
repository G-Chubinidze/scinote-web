# frozen_string_literal: true

Canaid::Permissions.register_for(Project) do
  include PermissionExtends

  # Project must be active for all the specified permissions
  %i(manage_project
     archive_project
     create_project_experiments
     create_project_comments
     manage_project_tags
     manage_project_users)
    .each do |perm|
    can perm do |_, project|
      project.active?
    end
  end

  %i(read_project
     export_project)
    .each do |perm|
    can perm do |user, project|
      user.is_admin_of_team?(project.team) || project.permission_granted?(user, ProjectPermissions::READ)
    end
  end

  can :manage_project do |user, project|
    project.permission_granted?(user, ProjectPermissions::MANAGE) &&
      project.experiments.each do |experiment|
        experiment.my_modules.all? do |my_module|
          if my_module.my_module_status
            my_module.my_module_status.my_module_status_implications.all? { |implication| implication.call(my_module) }
          else
            true
          end
        end
      end
  end

  can :read_project_users do |user, project|
    project.permission_granted?(user, ProjectPermissions::USERS_READ)
  end

  can :read_project_activities do |user, project|
    project.permission_granted?(user, ProjectPermissions::ACTIVITIES_READ)
  end

  can :manage_project_users do |user, project|
    user.is_admin_of_team?(project.team) || project.permission_granted?(user, ProjectPermissions::USERS_MANAGE)
  end

  can :archive_project do |user, project|
    project.permission_granted?(user, ProjectPermissions::MANAGE)
  end

  can :restore_project do |user, project|
    project.archived? && project.permission_granted?(user, ProjectPermissions::MANAGE)
  end

  can :create_project_experiments do |user, project|
    project.permission_granted?(user, ProjectPermissions::EXPERIMENTS_CREATE)
  end

  can :read_project_comments do |user, project|
    project.permission_granted?(user, ProjectPermissions::COMMENTS_READ)
  end

  can :create_project_comments do |user, project|
    project.permission_granted?(user, ProjectPermissions::COMMENTS_CREATE)
  end

  can :manage_project_tags do |user, project|
    project.permission_granted?(user, ProjectPermissions::TAGS_MANAGE)
  end

  can :manage_project_my_modules do |user, project|
    project.permission_granted?(user, ProjectPermissions::TASKS_MANAGE)
  end
end

Canaid::Permissions.register_for(ProjectComment) do
  %i(manage_project_comment)
    .each do |perm|
    can perm do |_, comment|
      project = comment.project
      project.active?
    end
  end

  can :manage_project_comment do |user, comment|
    project = comment.project
    project.permission_granted?(user, ProjectPermissions::COMMENTS_MANAGE) ||
      ((comment.user == user) && project.permission_granted?(user, ProjectPermissions::COMMENTS_MANAGE_OWN))
  end
end
