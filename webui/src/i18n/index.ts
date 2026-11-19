// src/i18n/index.ts
import { watchEffect } from 'vue';
import { createI18n } from 'vue-i18n';
import en from './locales/en';
import zh from './locales/zh';

const messages = {
  en,
  zh
};

const savedLanguage = localStorage.getItem('app_lang');

const i18n = createI18n({
  legacy: false,
  locale: savedLanguage === 'zh' ? 'zh' : 'en',
  fallbackLocale: 'en',
  messages,
});

watchEffect(() => {
  document.documentElement.lang = i18n.global.locale.value;
});

export default i18n;
