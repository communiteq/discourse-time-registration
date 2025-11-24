import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import DButton from "discourse/components/d-button";
import DModal from "discourse/components/d-modal";
import { Input } from "@ember/component";
import i18n from "discourse/helpers/i18n";

export default class TimeRegistrationStart extends Component {
  @tracked description = "";

  @action
  save() {
    this.args.model.save(this.description);
    this.args.closeModal();
  }

  <template>
    <DModal
      @title={{i18n "time_registration.start"}}
      @closeModal={{@closeModal}}
      class="time-registration-start-modal"
    >
      <:body>
        <div class="control-group">
          <label>{{i18n "time_registration.description_placeholder"}}</label>
          <Input
            @type="text"
            @value={{this.description}}
            class="form-control"
            autofocus="autofocus"
          />
        </div>
      </:body>

      <:footer>
        <DButton
          @action={{this.save}}
          @label="time_registration.confirm_start"
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