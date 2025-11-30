import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import DButton from "discourse/components/d-button";
import DModal from "discourse/components/d-modal";
import { Input } from "@ember/component";
import i18n from "discourse/helpers/i18n";

export default class TimeRegistrationEdit extends Component {
  @tracked description = "";
  @tracked duration = "";
  @tracked date = "";

  constructor() {
    super(...arguments);
    const post = this.args.model.post;

    // Load existing values
    this.description = post.time_registration_description ||
                       post.custom_fields?.time_registration_description || "";

    const amount = post.time_registration_amount ||
                   post.custom_fields?.time_registration_amount || 0;

    this.duration = this.formatDuration(amount);

    // Initialize date (YYYY-MM-DD)
    if (post.created_at) {
      this.date = post.created_at.substring(0, 10);
    }
  }

  formatDuration(seconds) {
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    return `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}`;
  }

  get maxDate() {
    return new Date().toISOString().split('T')[0];
  }

  @action
  save() {
    let minutes = 0;
    if (this.duration) {
        const [h, m] = this.duration.split(":").map(n => parseInt(n, 10) || 0);
        minutes = (h * 60) + m;
    }

    this.args.model.save(this.description, minutes, this.date);
    this.args.closeModal();
  }

  <template>
    <DModal
      @title={{i18n "time_registration.edit"}}
      @closeModal={{@closeModal}}
      class="time-registration-edit-modal"
    >
      <:body>
        <div class="control-group">
          <label>{{i18n "time_registration.description_placeholder"}}</label>
          <Input
            @type="text"
            @value={{this.description}}
            class="form-control"
          />
        </div>

        <div class="control-group">
          <label>{{i18n "time_registration.duration_placeholder"}}</label>
          <Input
            @type="text"
            @value={{this.duration}}
            class="form-control time-input"
            placeholder="HH:MM"
          />
        </div>

        <div class="control-group">
          <label>{{i18n "time_registration.date_placeholder"}}</label>
          <Input
            @type="date"
            @value={{this.date}}
            class="form-control"
            max={{this.maxDate}}
          />
        </div>
      </:body>

      <:footer>
        <DButton
          @action={{this.save}}
          @label="time_registration.save"
          class="btn-primary"
        />
        <DButton
          @action={{@closeModal}}
          @label="time_registration.cancel"
          class="btn-flat"
        />
      </:footer>
    </DModal>
  </template>
}