import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import withEventValue from "discourse/helpers/with-event-value";
import { i18n } from "discourse-i18n";

export default class GuestCommentDelaySettings extends Component {
  @service siteSettings;

  @action
  onChangeCategoryOverride(value) {
    this.args.outletArgs.category.set(
      "custom_fields.guest_comment_delay_minutes_override",
      value
    );
  }

  <template>
    {{#if this.siteSettings.enable_simplified_category_creation}}
      <@outletArgs.form.Section
        @title={{i18n "guest_comment_delay.category_override_label"}}
        class="category-custom-settings-outlet guest-comment-delay-settings"
      >
        <@outletArgs.form.Object @name="custom_fields" as |customFields|>
          <customFields.Field
            @name="guest_comment_delay_minutes_override"
            @title={{i18n "guest_comment_delay.category_override_label"}}
            @description={{i18n "guest_comment_delay.category_override_description"}}
            @type="input-number"
            as |field|
          >
            <field.Control min="0" />
          </customFields.Field>
        </@outletArgs.form.Object>
      </@outletArgs.form.Section>
    {{else}}
      <div class="category-custom-settings-outlet guest-comment-delay-settings">
        <section class="field">
          <label for="guest-comment-delay-minutes-override">
            {{i18n "guest_comment_delay.category_override_label"}}
          </label>

          <input
            id="guest-comment-delay-minutes-override"
            {{on "input" (withEventValue this.onChangeCategoryOverride)}}
            value={{@outletArgs.category.custom_fields.guest_comment_delay_minutes_override}}
            type="number"
            min="0"
          />

          <div class="instructions">
            {{i18n "guest_comment_delay.category_override_description"}}
          </div>
        </section>
      </div>
    {{/if}}
  </template>
}
