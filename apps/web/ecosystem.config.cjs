module.exports = {
  apps: [
    {
      name: 'ingredient-detective-web',
      exec_mode: 'cluster',
      instances: 'max',
      script: './.output/server/index.mjs',
      env: {
        NODE_ENV: 'production',
        PORT: 3000,
        HOST: '0.0.0.0'
      },
      error_file: './logs/error.log',
      out_file: './logs/out.log',
      log_file: './logs/combined.log',
      time: true,
      max_memory_restart: '1G',
      restart_delay: 4000,
      max_restarts: 10,
      min_uptime: '10s',
      autorestart: true,
      watch: false,
      ignore_watch: ['node_modules', 'logs', '.output'],
      merge_logs: true
    }
  ]
};
