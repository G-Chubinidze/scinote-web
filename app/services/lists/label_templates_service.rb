# frozen_string_literal: true

module Lists
  class LabelTemplatesService < BaseService
    private

    def fetch_records
      res = @raw_data.joins(
        'LEFT OUTER JOIN users AS creators ' \
        'ON label_templates.created_by_id = creators.id'
      ).joins(
        'LEFT OUTER JOIN users AS modifiers ' \
        'ON label_templates.last_modified_by_id = modifiers.id'
      ).select('label_templates.* AS label_templates')
                     .select('creators.full_name AS created_by_user')
                     .select('modifiers.full_name AS modified_by')
                     .select(
                       "('#{Extends::LABEL_TEMPLATE_FORMAT_MAP.to_json}'::jsonb -> label_templates.type)::text " \
                       "AS label_format"
                     )
      LabelTemplate.from(res, :label_templates)
    end

    def filter_records(records)
      return records unless @params[:search]

      records.where_attributes_like(
        ['label_templates.name', 'label_templates.label_format', 'label_templates.description',
         'label_templates.modified_by', 'label_templates.created_by_user'],
        @params[:search]
      )
    end

    def sortable_columns
      @sortable_columns ||= {
        default: 'label_templates.default',
        name: 'label_templates.name',
        format: 'label_templates.type',
        description: 'label_templates.description',
        modified_by: 'label_templates.modified_by',
        updated_at: 'label_templates.updated_at',
        created_by: 'label_templates.created_by_user',
        created_at: 'label_templates.created_at'
      }
    end
  end
end
