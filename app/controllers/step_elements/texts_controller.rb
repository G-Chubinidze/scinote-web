# frozen_string_literal: true

module StepElements
  class TextsController < BaseController
    before_action :load_step_text, only: %i(update destroy)

    def create
      step_text = @step.step_texts.build

      ActiveRecord::Base.transaction do
        create_in_step!(@step, step_text)
        log_step_activity(:text_added, { text_name: step_text.name })
      end

      render_step_orderable_element(step_text)
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end

    def update
      ActiveRecord::Base.transaction do
        @step_text.update!(step_text_params)
        TinyMceAsset.update_images(@step_text, params[:tiny_mce_images], current_user)
        log_step_activity(:text_edited, { text_name: @step_text.name })
      end

      render json: @step_text, serializer: StepTextSerializer, user: current_user
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end

    def destroy
      if @step_text.destroy
        log_step_activity(:text_deleted, { text_name: @step_text.name })
        head :ok
      else
        head :unprocessable_entity
      end
    end

    private

    def step_text_params
      params.require(:step_text).permit(:text)
    end

    def load_step_text
      @step_text = @step.step_texts.find_by(id: params[:id])
      return render_404 unless @step_text
    end
  end
end
