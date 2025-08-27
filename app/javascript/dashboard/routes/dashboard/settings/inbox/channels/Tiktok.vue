<script setup>
import { ref, onMounted, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import tiktokClient from 'dashboard/api/channel/tiktokClient';

const { t } = useI18n();
const hasError = ref(false);
const errorStateMessage = ref('');
const errorStateDescription = ref('');
const isRequestingAuthorization = ref(false);

// Computed properties for TikTok limitations to avoid ESLint errors
const limitationsTitle = computed(
  () => 'TikTok Business Messaging Limitations:'
);
const limitations = computed(() => [
  '48-hour messaging window with 10 message limit per window',
  'Text messages limited to 6,000 characters',
  'Only JPG/PNG images up to 3MB supported',
  'Video and voice messages not supported',
  'Not available for US organizations',
]);

onMounted(() => {
  const urlParams = new URLSearchParams(window.location.search);
  const errorCode = urlParams.get('code');
  const errorMessage = urlParams.get('error_message');

  if (errorMessage) {
    hasError.value = true;
    if (errorCode === '400') {
      errorStateMessage.value = errorMessage;
      errorStateDescription.value = t('INBOX_MGMT.ADD.TIKTOK.ERROR_AUTH');
    } else {
      errorStateMessage.value = t('INBOX_MGMT.ADD.TIKTOK.ERROR_MESSAGE');
      errorStateDescription.value = errorMessage;
    }
  }
  // User need to remove the error params from the url to avoid the error to be shown again after page reload
  const cleanURL = window.location.pathname;
  window.history.replaceState({}, document.title, cleanURL);
});

const requestAuthorization = async () => {
  isRequestingAuthorization.value = true;
  const response = await tiktokClient.generateAuthorization();
  const {
    data: { url },
  } = response;

  window.location.href = url;
};
</script>

<template>
  <div
    class="border border-n-weak bg-n-background h-full p-6 w-full max-w-full md:w-3/4 md:max-w-[75%] flex-shrink-0 flex-grow-0"
  >
    <div class="flex flex-col items-center justify-start h-full text-center">
      <div v-if="hasError" class="max-w-lg mx-auto text-center">
        <h5>{{ errorStateMessage }}</h5>
        <p
          v-if="errorStateDescription"
          v-dompurify-html="errorStateDescription"
        />
      </div>
      <div
        v-else
        class="flex flex-col items-center justify-center px-8 py-10 text-center shadow rounded-3xl outline outline-1 outline-n-weak"
      >
        <h6 class="text-2xl font-medium">
          {{ $t('INBOX_MGMT.ADD.TIKTOK.CONNECT_YOUR_TIKTOK_BUSINESS') }}
        </h6>
        <p class="py-6 text-sm text-n-slate-11">
          {{ $t('INBOX_MGMT.ADD.TIKTOK.HELP') }}
        </p>

        <!-- TikTok Limitations Warning -->
        <div class="mb-6 p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
          <div class="flex items-start">
            <span
              class="i-ri-information-line size-5 text-yellow-600 mt-0.5 mr-3 flex-shrink-0"
            />
            <div class="text-sm text-yellow-800">
              <p class="font-medium mb-2">{{ limitationsTitle }}</p>
              <ul class="list-disc list-inside space-y-1 text-xs">
                <li v-for="limitation in limitations" :key="limitation">
                  {{ limitation }}
                </li>
              </ul>
            </div>
          </div>
        </div>
        <button
          class="flex items-center justify-center px-8 py-3.5 gap-2 text-white rounded-full bg-gradient-to-r from-[#000000] to-[#25F4EE] hover:shadow-lg transition-all duration-300 min-w-[240px] overflow-hidden"
          :disabled="isRequestingAuthorization"
          @click="requestAuthorization()"
        >
          <span class="i-ri-tiktok-line size-5" />
          <span class="text-base font-medium">
            {{ $t('INBOX_MGMT.ADD.TIKTOK.CONTINUE_WITH_TIKTOK') }}
          </span>
          <span v-if="isRequestingAuthorization" class="ml-2">
            <svg
              class="w-5 h-5 animate-spin"
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
            >
              <circle
                class="opacity-25"
                cx="12"
                cy="12"
                r="10"
                stroke="currentColor"
                stroke-width="4"
              />
              <path
                class="opacity-75"
                fill="currentColor"
                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
              />
            </svg>
          </span>
        </button>
      </div>
    </div>
  </div>
</template>
