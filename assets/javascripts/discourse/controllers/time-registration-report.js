import Controller from "@ember/controller";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import I18n from "discourse-i18n";

export default class TimeRegistrationReportController extends Controller {
  @tracked fromDate = null;
  @tracked toDate = null;
  @tracked categoryId = null;
  @tracked selectedUsernames = [];
  @tracked reportData = [];
  @tracked isLoading = false;
  @tracked hasSearched = false;

  formatDuration(seconds) {
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    return `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}`;
  }

  @action
  updateFromDate(e) {
    this.fromDate = e.target.value;
  }

  @action
  updateToDate(e) {
    this.toDate = e.target.value;
  }

  @action
  updateCategory(categoryId) {
    this.categoryId = categoryId;
  }

  @action
  updateUser(usernames) {
    this.selectedUsernames = usernames;
  }

  @action
  resetFilters() {
    this.fromDate = null;
    this.toDate = null;
    this.categoryId = null;
    this.selectedUsernames = [];
    this.reportData = [];
    this.hasSearched = false;

    // Reset date inputs manually since they are not bound via @value
    const dateInputs = document.querySelectorAll('.time-registration-report .date-picker');
    dateInputs.forEach(input => input.value = '');
  }

  get totalDuration() {
    if (!this.reportData || this.reportData.length === 0) {
      return "00:00";
    }

    const totalSeconds = this.reportData.reduce((sum, row) => sum + (row.duration_seconds || 0), 0);

    const h = Math.floor(totalSeconds / 3600);
    const m = Math.floor((totalSeconds % 3600) / 60);

    return `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}`;
  }

  @action
  async generateReport() {
    this.isLoading = true;
    try {
      const result = await ajax("/time-registration/report", {
        data: {
          from: this.fromDate,
          to: this.toDate,
          category_id: this.categoryId,
          username: this.selectedUsernames[0],
        },
      });
      this.hasSearched = true;
      // Process data for display
      this.reportData = result.report.map(row => ({
        ...row,
        formattedDuration: this.formatDuration(row.duration_seconds),
        topicUrl: `/t/${row.topic_id}/${row.post_number}`,
        // Use browser's native locale formatting
        formattedDate: new Date(row.created_at).toLocaleDateString()
      }));
    } catch (e) {
      popupAjaxError(e);
    } finally {
      this.isLoading = false;
    }
  }
}