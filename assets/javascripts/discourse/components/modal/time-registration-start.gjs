import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import DButton from "discourse/components/d-button";
import DModal from "discourse/components/d-modal";
import { Input } from "@ember/component";
import i18n from "discourse/helpers/i18n";
import { fn } from "@ember/helper";
import eq from "truth-helpers/helpers/eq";
import not from "truth-helpers/helpers/not";

export default class TimeRegistrationStart extends Component {
  @tracked description = "";
  @tracked duration = ""; // HH:MM format or minutes
  @tracked mode = "timer"; // 'timer' or 'manual'

  @action
  setMode(mode) {
    this.mode = mode;
  }

  get parsedMinutes() {
    if (!this.duration) {
      return 0;
    }

    // If it contains a colon, treat as HH:MM
    if (this.duration.includes(":")) {
      const [h, m] = this.duration.split(":").map((n) => parseInt(n, 10) || 0);
      return h * 60 + m;
    } else {
      // Otherwise treat as minutes
      return parseInt(this.duration, 10) || 0;
    }
  }

  get isManualValid() {
    return this.parsedMinutes > 0;
  }

  @action
  saveTimer() {
    this.args.model.saveTimer(this.description);
    this.args.closeModal();
  }

  @action
  saveManual() {
    this.args.model.saveManual(this.description, this.parsedMinutes);
    this.args.closeModal();
  }

  <template>
    <DModal
      @title={{i18n "time_registration.title"}}
      @closeModal={{@closeModal}}
      class="time-registration-start-modal"
    >
      <:body>
        <div class="time-registration-modes" style="margin-bottom: 15px;">
          <DButton
            @action={{fn this.setMode "timer"}}
            @label="time_registration.confirm_start"
            class={{if (eq this.mode "timer") "btn-primary" "btn-default"}}
          />
          <DButton
            @action={{fn this.setMode "manual"}}
            @label="time_registration.confirm_manual"
            class={{if (eq this.mode "manual") "btn-primary" "btn-default"}}
          />
        </div>

        <div class="control-group">
          <label>{{i18n "time_registration.description_placeholder"}}</label>
          <Input
            @type="text"
            @value={{this.description}}
            class="form-control"
            autofocus="autofocus"
          />
        </div>

        {{#if (eq this.mode "manual")}}
          <div class="control-group">
            <label>{{i18n "time_registration.duration_placeholder"}}</label>
            <Input
              @type="text"
              @value={{this.duration}}
              class="form-control"
              placeholder="HH:MM or minutes"
            />
          </div>
        {{/if}}
      </:body>

      <:footer>
        {{#if (eq this.mode "timer")}}
          <DButton
            @action={{this.saveTimer}}
            @label="time_registration.confirm_start"
            class="btn-primary"
          />
        {{else}}
          <DButton
            @action={{this.saveManual}}
            @label="time_registration.confirm_manual"
            class="btn-primary"
            @disabled={{not this.isManualValid}}
          />
        {{/if}}
        <DButton
          @action={{@closeModal}}
          @label="time_registration.cancel"
          class="btn-flat"
        />
      </:footer>
    </DModal>
  </template>
}