// vitest.config.js
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'clarinet',
    environmentOptions: {
      coverageFilename: 'coverage.json', // Add this to avoid undefined error
    },
  },
});
