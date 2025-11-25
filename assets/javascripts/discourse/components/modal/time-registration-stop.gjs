import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import DButton from "discourse/components/d-button";
import DModal from "discourse/components/d-modal";
import { Input } from "@ember/component";
import i18n from "discourse/helpers/i18n";

export default class TimeRegistrationStop extends Component {
  @tracked description = this.args.model.currentDescription || "";
  @tracked duration = ""; // Optional override

  @action
  save() {
    // If duration is entered, parse it
    let minutes = null;
    if (this.duration) {
        const [h, m] = this.duration.split(":").map(n => parseInt(n, 10) || 0);
        minutes = (h * 60) + m;
    }

    this.args.model.save(this.description, minutes);
    this.args.closeModal();
  }

  <template>
    <DModal
      @title={{i18n "time_registration.stop"}}
      @closeModal={{@closeModal}}
      class="time-registration-stop-modal"
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
          <label>{{i18n "time_registration.duration_placeholder"}} (Optional override)</label>
          <Input
            @type="text"
            @value={{this.duration}}
            class="form-control"
            placeholder="Leave empty to use timer"
          />
        </div>
      </:body>

      <:footer>
        <DButton
          @action={{this.save}}
          @label="time_registration.confirm_stop"
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