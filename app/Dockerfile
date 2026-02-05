# Use a lightweight official Python image
FROM python:3.9-slim

# Set the working directory inside the container
WORKDIR /app

# Copy only requirements first to leverage Docker cache
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code (app.py)
COPY . .

# Expose the Flask port
EXPOSE 5001

# Run the application
CMD ["python", "app.py"]