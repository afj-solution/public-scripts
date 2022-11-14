const config = {
    use: {
      ignoreHTTPSErrors: true,
      headless: true,
      args: [
        "--no-sandbox",
        "--disable-setuid-sandbox",
        "--start-fullscreen",
        "--disable-gpu",
        "--disable-dev-shm-usage",
        "--disable-popup-blocking",
      ],
      viewport: { width: 1024, height: 720 },
      screenshot: "on",
      video: "on",
    },
    reporter: [["dot"], ["allure-playwright"]],
    timeout: 200000,
    workers: 10,
  };
  
  module.exports = config;
  