CREATE TABLE IF NOT EXISTS users (
  id           VARCHAR(255) PRIMARY KEY,
  full_name    VARCHAR(255) NOT NULL,
  email        VARCHAR(255) NOT NULL UNIQUE,
  password     VARCHAR(255) NOT NULL,
  weight               FLOAT DEFAULT NULL,
  role                 VARCHAR(255) NOT NULL DEFAULT 'user',
  gender               VARCHAR(50) DEFAULT NULL,
  fitness_goal         VARCHAR(100) DEFAULT NULL,
  target_weight        FLOAT DEFAULT NULL,
  onboarding_completed BOOLEAN DEFAULT FALSE,
  date_created         TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);