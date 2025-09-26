// Test setup for result service
const { GenericContainer } = require('testcontainers');

// Global test configuration
global.testConfig = {
  timeout: 30000,
  containers: {}
};

// Cleanup function for containers
global.cleanupContainers = async () => {
  const containers = global.testConfig.containers;
  for (const [name, container] of Object.entries(containers)) {
    try {
      await container.stop();
      console.log(`Stopped container: ${name}`);
    } catch (error) {
      console.error(`Error stopping container ${name}:`, error.message);
    }
  }
  global.testConfig.containers = {};
};

// Setup before all tests
beforeAll(async () => {
  // Any global setup can go here
});

// Cleanup after all tests
afterAll(async () => {
  await global.cleanupContainers();
});
