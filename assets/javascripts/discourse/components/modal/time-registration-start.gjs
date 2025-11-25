import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import DButton from "discourse/components/d-button";
import DModal from "discourse/components/d-modal";
import { Input } from "@ember/component";
import i18n from "discourse/helpers/i18n";
import { fn } from "@ember/helper";
import eq from "truth-helpers/helpers/eq";

export default class TimeRegistrationStart extends Component {
  @tracked description = "";
  @tracked duration = ""; // HH:MM format
  @tracked mode = "timer"; // 'timer' or 'manual'

  @action
  setMode(mode) {
    this.mode = mode;
  }

  @action
  saveTimer() {
    this.args.model.saveTimer(this.description);
    this.args.closeModal();
  }

  @action
  saveManual() {
    // Parse HH:MM to minutes
    const [hours, minutes] = this.duration.split(":").map(n => parseInt(n, 10) || 0);
    const totalMinutes = (hours * 60) + minutes;

    this.args.model.saveManual(this.description, totalMinutes);
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
              placeholder="01:30"
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