# frozen_string_literal: true

module PwaHelper
  def pwa_mobile_app_url(team_id, project_id, experiment_id, task_id, protocol_id, step_id)
    url = Constants::PWA_URL
    {
      ':pwa_domain' => Rails.configuration.x.pwa_domain,
      ':team_id' => team_id,
      ':project_id' => project_id,
      ':experiment_id' => experiment_id,
      ':task_id' => task_id,
      ':protocol_id' => protocol_id,
      ':step_id' => step_id
    }.each { |k, v| url.gsub!(k, v.to_s) }
    url
  end
end
