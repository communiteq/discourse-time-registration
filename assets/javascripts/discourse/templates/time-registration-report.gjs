import { hash } from "@ember/helper";
import RouteTemplate from 'ember-route-template';
import DButton from "discourse/components/d-button";
import avatar from "discourse/helpers/avatar";
import { i18n } from "discourse-i18n";
import CategoryChooser from "select-kit/components/category-chooser";
import UserChooser from "select-kit/components/user-chooser";

export default RouteTemplate(
  <template>{{!-- filepath: /var/www/discourse/plugins/discourse-time-registration/assets/javascripts/discourse/templates/time-registration-report.hbs --}}
    <div class="time-registration-report">
      <h1>{{i18n "time_registration.report.title"}}</h1>

      <div class="report-filters">
        <div class="filter-group">
          <label>{{i18n "time_registration.report.from"}}</label>
          <input type="date" class="date-picker" onchange={{@controller.updateFromDate}} />
        </div>

        <div class="filter-group">
          <label>{{i18n "time_registration.report.to"}}</label>
          <input type="date" class="date-picker" onchange={{@controller.updateToDate}} />
        </div>

        <div class="filter-group">
          <label>{{i18n "category_title"}}</label>
          <CategoryChooser @value={{@controller.categoryId}} @onChange={{@controller.updateCategory}} />
        </div>

        <div class="filter-group">
          <label>{{i18n "time_registration.report.user"}}</label>
          <UserChooser @value={{@controller.selectedUsernames}} @onChange={{@controller.updateUser}} @options={{hash maximum=1}} />
        </div>

        <div class="filter-actions">
          <DButton @action={{@controller.generateReport}} @label="time_registration.report.generate" @icon="rotate" @disabled={{@controller.isLoading}} class="btn-primary" />
          <DButton @action={{@controller.resetFilters}} @label="time_registration.report.reset" @icon="rotate-left" class="btn-default" />
        </div>
      </div>

      {{#if @controller.reportData}}
        <div class="report-summary" style="margin-bottom: 15px; font-size: 1.2em;">
          <strong>{{i18n "time_registration.report.total_duration"}}:</strong>
          {{@controller.totalDuration}}
        </div>

        <table class="table time-report-table">
          <thead>
            <tr>
              <th>{{i18n "time_registration.report.category"}}</th>
              <th>{{i18n "time_registration.report.user"}}</th>
              <th>{{i18n "time_registration.report.topic"}}</th>
              <th>{{i18n "time_registration.report.description"}}</th>
              <th>{{i18n "time_registration.report.time_spent"}}</th>
              <th>{{i18n "time_registration.report.date"}}</th>
            </tr>
          </thead>
          <tbody>
            {{#each @controller.reportData as |row|}}
              <tr>
                <td>{{row.category_name}}</td>
                <td>
                  <a href="/u/{{row.username}}" data-user-card={{row.username}}>
                    {{avatar row imageSize="tiny"}}
                    {{row.username}}
                  </a>
                </td>
                <td><a href={{row.topicUrl}}>{{row.topic_title}}</a></td>
                <td>{{row.description}}</td>
                <td>{{row.formattedDuration}}</td>
                <td>{{row.formattedDate}}</td>
              </tr>
            {{/each}}
          </tbody>
        </table>
      {{else}}
        {{#if @controller.hasSearched}}
          <div class="no-results">
            {{i18n "time_registration.report.no_results"}}
          </div>
        {{/if}}
      {{/if}}
    </div>
  </template>
);