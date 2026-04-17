#!/bin/bash
set -e

# ---------- FUNCTION ----------
npm_install_and_build() {
  CURRENT_DIR=$1

  echo "Working in $CURRENT_DIR"
  cd "$CURRENT_DIR" || { echo "Error: Invalid path"; return 1; }

  read -p "Run npm install in $(basename "$CURRENT_DIR")? (y/n): " RUN_INSTALL

  if [[ "$RUN_INSTALL" == "y" ]]; then
    read -p "Use --legacy-peer-deps? (y/n): " USE_LEGACY

    if [[ "$USE_LEGACY" == "y" ]]; then
      npm install --legacy-peer-deps
    else
      npm install
    fi
  fi

  read -p "Run build (npm run build) in $(basename "$CURRENT_DIR")? (y/n): " RUN_BUILD

  if [[ "$RUN_BUILD" == "y" ]]; then
    npm run build
  fi
}
# --------------------------------

# Ask for project path
read -p "Enter project path: " PROJECT_PATH

# Expand ~ to home directory
PROJECT_PATH="${PROJECT_PATH/#\~/$HOME}"

if [ -z "$PROJECT_PATH" ]; then
  echo "Error: Project path is required"
  exit 1
fi

cd "$PROJECT_PATH" || { echo "Error: Invalid path"; exit 1; }

# Git pull
read -p "Pull latest code? (y/n): " PULL_CODE
if [[ "$PULL_CODE" == "y" ]]; then
  git pull
fi

# ---------- FRONTEND ----------
read -p "Run deployment steps for frontend? (y/n): " RUN_FRONTEND

if [[ "$RUN_FRONTEND" == "y" ]]; then
  read -p "Provide the folder name of frontend: " FRONTEND_FOLDER
  npm_install_and_build "$PROJECT_PATH/$FRONTEND_FOLDER"
fi

# ---------- BACKEND ----------
read -p "Run deployment steps for backend? (y/n): " RUN_BACKEND
if [[ "$RUN_BACKEND" == "y" ]]; then
  read -p "Provide the folder name of backend: " BACKEND_FOLDER
  npm_install_and_build "$PROJECT_PATH/$BACKEND_FOLDER"
fi

# ---------- PM2 RESTART ----------
read -p "Do you want to restart a PM2 process? (y/n): " RESTART_PM2

if [[ "$RESTART_PM2" == "y" ]]; then
  read -p "Would you like to run in root or user dir? (r/a): " DIR_TYPE

  if [[ "$DIR_TYPE" == "a" ]]; then
    read -p "Provide the admin name: " ADMIN_NAME

    echo "Fetching PM2 processes for $ADMIN_NAME..."
    su - "$ADMIN_NAME" -c "pm2 ls"

    read -p "Enter PM2 app name or id: " PM2_NAME

    echo "Restarting PM2 app as $ADMIN_NAME..."
    su - "$ADMIN_NAME" -c "pm2 restart \"$PM2_NAME\""
  else
    pm2 ls
    read -p "Enter PM2 app name or id: " PM2_NAME
    pm2 restart "$PM2_NAME"
  fi
fi

echo "Deployment flow completed successfully"
