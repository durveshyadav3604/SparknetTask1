#!/usr/bin/env bash
# Register a new ECS task-definition revision pointing at a freshly built
# image, then update the service to use it and wait for it to go stable.
#
# Usage: deploy-ecs-service.sh <cluster> <service> <task-family> <container-name> <image-uri>
set -euo pipefail

CLUSTER="$1"
SERVICE="$2"
TASK_FAMILY="$3"
CONTAINER_NAME="$4"
IMAGE="$5"

echo "==> Fetching current task definition: $TASK_FAMILY"
CURRENT_TASK_DEF=$(aws ecs describe-task-definition \
  --task-definition "$TASK_FAMILY" \
  --query 'taskDefinition')

echo "==> Building new task definition with image: $IMAGE"
NEW_TASK_DEF=$(echo "$CURRENT_TASK_DEF" | jq --arg IMAGE "$IMAGE" --arg NAME "$CONTAINER_NAME" '
  .containerDefinitions = [
    .containerDefinitions[] | if .name == $NAME then .image = $IMAGE else . end
  ]
  | {
      family, taskRoleArn, executionRoleArn, networkMode, containerDefinitions,
      volumes, placementConstraints, requiresCompatibilities, cpu, memory
    }
')

echo "==> Registering new task definition revision"
NEW_TASK_DEF_ARN=$(aws ecs register-task-definition \
  --cli-input-json "$NEW_TASK_DEF" \
  --query 'taskDefinition.taskDefinitionArn' \
  --output text)

echo "==> Registered: $NEW_TASK_DEF_ARN"

echo "==> Updating service $SERVICE to use the new revision"
aws ecs update-service \
  --cluster "$CLUSTER" \
  --service "$SERVICE" \
  --task-definition "$NEW_TASK_DEF_ARN" \
  --force-new-deployment > /dev/null

echo "==> Waiting for service to reach steady state (this can take a few minutes)"
aws ecs wait services-stable \
  --cluster "$CLUSTER" \
  --services "$SERVICE"

echo "==> Deployment complete: $SERVICE is running $NEW_TASK_DEF_ARN"
