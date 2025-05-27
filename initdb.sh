#!/usr/bin/env bash
export $(grep -E '^(POSTGRES_DB|POSTGRES_USER)=' .env | xargs)

echo "Copying SQL files to container..."
docker exec -i postgres mkdir -p /tmp/sql
for file in $(find sql -name "*.sql"); do
  echo "Copying $file..."
  docker cp "$file" postgres:/tmp/"$file"
done

echo "Executing SQL files against $POSTGRES_DB database..."
docker exec -i postgres bash -c "cd /tmp/sql && psql -d \"$POSTGRES_DB\" -U \"$POSTGRES_USER\" \
  -v ON_ERROR_STOP=1 \
  -P pager=off \
  -P format=aligned \
  -e \
  -a \
  -f main.sql"
  
echo "SQL execution complete with exit code $?"