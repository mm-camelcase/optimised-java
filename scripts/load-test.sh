#!/bin/bash

# Function to generate random user data
generate_user_data() {
  local id=$1
  local name="User$id"
  local email="user$id@example.com"
  echo '{"id":'"$id"', "name":"'"$name"'", "email":"'"$email"'"}'
}

# Start time tracking
start_time=$(date +%s)

# Remove user with ID 1
echo "Deleting user with ID 1..."
curl -X DELETE "http://localhost:8080/api/users/1" -H "Accept: application/json"
sleep 0.5  # Pause for 500ms

# Remove user with ID 2
echo "Deleting user with ID 2..."
curl -X DELETE "http://localhost:8080/api/users/2" -H "Accept: application/json"
sleep 0.5  # Pause for 500ms

# Loop to create 50 users with pauses
for i in {1..50}; do
  echo "Creating user $i..."
  curl -X POST "http://localhost:8080/api/users" \
  -H "Content-Type: application/json" \
  -d "$(generate_user_data $i)"
  sleep 0.1  # Pause for 100ms
done

# Pause to avoid overloading the server
sleep 2

# Loop to get all users multiple times with pauses
for i in {1..20}; do
  echo "Getting all users (iteration $i)..."
  curl -X GET "http://localhost:8080/api/users" -H "Accept: application/json"
  sleep 0.2  # Pause for 200ms
done

# Loop to get each user by ID with pauses
for i in {1..50}; do
  echo "Getting user $i by ID..."
  curl -X GET "http://localhost:8080/api/users/$i" -H "Accept: application/json"
  sleep 0.1  # Pause for 100ms
done

# Pause again
sleep 2

# Loop to update each user with pauses
for i in {1..50}; do
  echo "Updating user $i..."
  curl -X PUT "http://localhost:8080/api/users/$i" \
  -H "Content-Type: application/json" \
  -d '{"id":'"$i"', "name":"Updated User '"$i"'", "email":"updated.user'"$i"'@example.com"}'
  sleep 0.1  # Pause for 100ms
done

# Pause again
sleep 2

# Loop to delete half of the users with pauses
for i in {1..25}; do
  echo "Deleting user $i..."
  curl -X DELETE "http://localhost:8080/api/users/$i" -H "Accept: application/json"
  sleep 0.2  # Pause for 200ms
done

# End time tracking
end_time=$(date +%s)
duration=$((end_time - start_time))

echo "Script completed in $duration seconds."

