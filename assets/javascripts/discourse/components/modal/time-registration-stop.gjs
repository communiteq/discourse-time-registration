import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import DModal from "discourse/components/d-modal";
import { Input } from "@ember/component";
import i18n from "discourse/helpers/i18n";
import { on } from "@ember/modifier";

export default class TimeRegistrationStop extends Component {
  @service siteSettings;
  @tracked description = this.args.model.currentDescription || "";
  @tracked duration = "";
  @tracked _useRounding = true;

  constructor() {
    super(...arguments);
    this.calculateDuration();
  }

  get useRounding() {
    return this._useRounding;
  }

  set useRounding(val) {
    this._useRounding = val;
    this.calculateDuration();
  }

  calculateDuration() {
    if (!this.args.model.startTime) return;

    const now = Math.floor(Date.now() / 1000);
    const start = parseInt(this.args.model.startTime, 10);
    let seconds = Math.max(0, now - start);

    if (this.useRounding) {
        seconds = this.applyRounding(seconds);
    }

    this.duration = this.formatDuration(seconds);
  }

  applyRounding(seconds) {
      const minutes = seconds / 60.0;
      const interval = parseInt(this.siteSettings.time_registration_rounding_interval, 10);
      const roundUpAt = parseInt(this.siteSettings.time_registration_round_up_at, 10);

      if (interval <= 0) return seconds;

      const base = Math.floor(minutes / interval) * interval;
      const remainder = minutes % interval;

      let finalMinutes = remainder >= roundUpAt ? base + interval : base;
      finalMinutes = Math.max(finalMinutes, interval); // Ensure at least interval

      return Math.floor(finalMinutes * 60);
  }

  formatDuration(seconds) {
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    return `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}`;
  }

  @action
  toggleRounding() {
      this.useRounding = !this.useRounding;
  }

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
          <label>{{i18n "time_registration.duration_placeholder"}}</label>
          <div class="duration-input-wrapper" style="display: flex; align-items: center; gap: 10px;">
            <Input
                @type="text"
                @value={{this.duration}}
                class="form-control time-input"
                placeholder="HH:MM"
            />
            <label style="margin: 0; display: flex; align-items: center; cursor: pointer;">
                <input type="checkbox" checked={{this.useRounding}} {{on "change" this.toggleRounding}} />
                <span style="margin-left: 5px;">Round</span>
            </label>
          </div>
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