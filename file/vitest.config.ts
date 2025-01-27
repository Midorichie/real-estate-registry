import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    include: ['tests/**/*.test.ts'],
    environment: 'clarinet',
    // coverage: { reporter: ['text', 'html', 'json'] }, // Remove this for debugging
  },
});

