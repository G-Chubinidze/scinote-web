# frozen_string_literal: true

module Lists
  class ProtocolsService < BaseService
    PREFIXED_ID_SQL = "('#{Protocol::ID_PREFIX}' || COALESCE(\"protocols\".\"parent_id\", \"protocols\".\"id\"))".freeze

    private

    def fetch_records
      original_without_versions = @raw_data
                                  .left_outer_joins(:published_versions)
                                  .in_repository_published_original
                                  .where(published_versions: { id: nil })
                                  .select(:id)
      published_versions = @raw_data
                           .in_repository_published_version
                           .order(:parent_id, version_number: :desc)
                           .select('DISTINCT ON (parent_id) id')
      new_drafts = @raw_data
                   .where(protocol_type: Protocol.protocol_types[:in_repository_draft], parent_id: nil)
                   .select(:id)

      @records = Protocol.where('protocols.id IN (?) OR protocols.id IN (?) OR protocols.id IN (?)',
                                original_without_versions, published_versions, new_drafts)

      @records = @records.preload(:parent, :latest_published_version, :draft,
                                  :protocol_keywords, user_assignments: %i(user user_role))
                         .joins("LEFT OUTER JOIN protocols protocol_versions " \
                                "ON protocol_versions.protocol_type = #{Protocol.protocol_types[:in_repository_published_version]} " \
                                "AND protocol_versions.parent_id = protocols.parent_id")
                         .joins("LEFT OUTER JOIN protocols protocol_originals " \
                                "ON protocol_originals.protocol_type = #{Protocol.protocol_types[:in_repository_published_original]} " \
                                "AND protocol_originals.id = protocols.parent_id OR " \
                                "(protocols.id = protocol_originals.id AND protocols.parent_id IS NULL)")
                         .joins("LEFT OUTER JOIN protocols linked_task_protocols " \
                                "ON linked_task_protocols.protocol_type = #{Protocol.protocol_types[:linked]} " \
                                "AND (linked_task_protocols.parent_id = protocol_versions.id OR " \
                                "linked_task_protocols.parent_id = protocol_originals.id)")
                         .joins('LEFT OUTER JOIN "protocol_protocol_keywords" ' \
                                'ON "protocol_protocol_keywords"."protocol_id" = "protocols"."id"')
                         .joins('LEFT OUTER JOIN "protocol_keywords" ' \
                                'ON "protocol_protocol_keywords"."protocol_keyword_id" = "protocol_keywords"."id"')
                         .joins('LEFT OUTER JOIN "users" "archived_users" ON "archived_users"."id" = "protocols"."archived_by_id"')
                         .joins('LEFT OUTER JOIN "users" ON "users"."id" = "protocols"."published_by_id"')
                         .joins('LEFT OUTER JOIN "user_assignments" "all_user_assignments" ' \
                                'ON "all_user_assignments"."assignable_type" = \'Protocol\' ' \
                                'AND "all_user_assignments"."assignable_id" = "protocols"."id"')
                         .group('"protocols"."id"')
                         .select(
                           '"protocols".*',
                           'COALESCE("protocols"."parent_id", "protocols"."id") AS adjusted_parent_id',
                           'STRING_AGG(DISTINCT("protocol_keywords"."name"), \', \') AS "protocol_keywords_str"',
                           "CASE WHEN protocols.protocol_type = #{Protocol.protocol_types[:in_repository_draft]} " \
                           "THEN 0 ELSE COUNT(DISTINCT(\"protocol_versions\".\"id\")) + 1 " \
                           "END AS nr_of_versions",
                           'COUNT(DISTINCT("linked_task_protocols"."id")) AS nr_of_linked_tasks',
                           'COUNT(DISTINCT("all_user_assignments"."id")) AS "nr_of_assigned_users"',
                           'MAX("users"."full_name") AS "full_username_str"', # "Hack" to get single username
                           'MAX("archived_users"."full_name") AS "archived_full_username_str"'
                         )

      view_mode = @params[:view_mode] || 'active'

      @records = @records.archived if view_mode == 'archived'
      @records = @records.active if view_mode == 'active'
    end

    def filter_records
      return if @params[:search].blank?

      @records = @records.where(
        "LOWER(\"protocols\".\"name\") LIKE :search OR
         LOWER(\"protocol_keywords\".\"name\") LIKE :search OR
         LOWER(#{PREFIXED_ID_SQL}) LIKE :search",
        search: "%#{@params[:search].to_s.downcase}%"
      )
    end

    def sortable_columns
      @sortable_columns ||= {
        name: 'name',
        code: 'id',
        parent_id: 'adjusted_parent_id',
        versions: 'nr_of_versions',
        keywords: 'protocol_keywords_str',
        linked_tasks: 'nr_of_linked_tasks',
        assigned_users: 'nr_of_assigned_users',
        published_by: 'full_username_str',
        published_on: 'published_on',
        udpated_at: 'updated_at',
        archived_by: 'archived_full_username_str',
        archived_on: 'archived_on'
      }
    end
  end
end