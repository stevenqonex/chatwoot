<script setup>
import { reactive, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { minLength } from '@vuelidate/validators';

import Button from 'dashboard/components-next/button/Button.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';

const props = defineProps({
  assistant: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['submit']);

const { t } = useI18n();

const initialState = {
  handoffMessage: '',
  resolutionMessage: '',
  temperature: 1,
  showPendingConversations: false,
};

const state = reactive({ ...initialState });

const validationRules = {
  handoffMessage: { minLength: minLength(1) },
  resolutionMessage: { minLength: minLength(1) },
};

const v$ = useVuelidate(validationRules, state);

const getErrorMessage = field => {
  return v$.value[field].$error ? v$.value[field].$errors[0].$message : '';
};

const formErrors = computed(() => ({
  handoffMessage: getErrorMessage('handoffMessage'),
  resolutionMessage: getErrorMessage('resolutionMessage'),
}));

const updateStateFromAssistant = assistant => {
  const { config = {} } = assistant;
  state.handoffMessage = config.handoff_message;
  state.resolutionMessage = config.resolution_message;
  state.temperature = config.temperature || 1;
  state.showPendingConversations = config.show_pending_conversations || false;
};

const handleSystemMessagesUpdate = async () => {
  const result = await Promise.all([
    v$.value.handoffMessage.$validate(),
    v$.value.resolutionMessage.$validate(),
  ]).then(results => results.every(Boolean));
  if (!result) return;

  const payload = {
    config: {
      ...props.assistant.config,
      handoff_message: state.handoffMessage,
      resolution_message: state.resolutionMessage,
      temperature: state.temperature || 1,
      show_pending_conversations: state.showPendingConversations,
    },
  };

  emit('submit', payload);
};

watch(
  () => props.assistant,
  newAssistant => {
    if (newAssistant) updateStateFromAssistant(newAssistant);
  },
  { immediate: true }
);

// Add these computed properties
const checkboxLabel = computed(
  () => 'Show AI conversations in unassigned dashboard'
);
const checkboxDescription = computed(
  () =>
    'When enabled, conversations being handled by Captain AI will be visible to agents in the unassigned dashboard with "AI Responding" status.'
);
</script>

<template>
  <div class="flex flex-col gap-6">
    <Editor
      v-model="state.handoffMessage"
      :label="t('CAPTAIN.ASSISTANTS.FORM.HANDOFF_MESSAGE.LABEL')"
      :placeholder="t('CAPTAIN.ASSISTANTS.FORM.HANDOFF_MESSAGE.PLACEHOLDER')"
      :message="formErrors.handoffMessage"
      :message-type="formErrors.handoffMessage ? 'error' : 'info'"
    />

    <Editor
      v-model="state.resolutionMessage"
      :label="t('CAPTAIN.ASSISTANTS.FORM.RESOLUTION_MESSAGE.LABEL')"
      :placeholder="t('CAPTAIN.ASSISTANTS.FORM.RESOLUTION_MESSAGE.PLACEHOLDER')"
      :message="formErrors.resolutionMessage"
      :message-type="formErrors.resolutionMessage ? 'error' : 'info'"
    />

    <div class="flex flex-col gap-2">
      <label class="text-sm font-medium text-n-slate-12">
        {{ t('CAPTAIN.ASSISTANTS.FORM.TEMPERATURE.LABEL') }}
      </label>
      <div class="flex items-center gap-4">
        <input
          v-model="state.temperature"
          type="range"
          min="0"
          max="1"
          step="0.1"
          class="w-full"
        />
        <span class="text-sm text-n-slate-12">{{ state.temperature }}</span>
      </div>
      <p class="text-sm text-n-slate-11 italic">
        {{ t('CAPTAIN.ASSISTANTS.FORM.TEMPERATURE.DESCRIPTION') }}
      </p>
    </div>

    <div class="flex flex-col gap-2">
      <label class="flex items-center gap-2">
        <input
          v-model="state.showPendingConversations"
          type="checkbox"
          class="rounded border-n-slate-7 text-n-slate-12 focus:ring-n-slate-8"
        />
        <span class="text-sm font-medium text-n-slate-12">
          {{ checkboxLabel }}
        </span>
      </label>
      <p class="text-sm text-n-slate-11 italic">
        {{ checkboxDescription }}
      </p>
    </div>

    <div>
      <Button
        :label="t('CAPTAIN.ASSISTANTS.FORM.UPDATE')"
        @click="handleSystemMessagesUpdate"
      />
    </div>
  </div>
</template>
