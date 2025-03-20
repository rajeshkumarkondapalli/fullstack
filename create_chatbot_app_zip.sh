#!/bin/bash

# Create the directory structure
mkdir -p chatbot_app/frontend/pages
mkdir -p chatbot_app/frontend/components
mkdir -p chatbot_app/backend

# Create the files
cat > chatbot_app/frontend/pages/index.js <<EOL
import ChatInterface from '../components/ChatInterface';

function Home() {
  return (
    <div>
      <ChatInterface />
    </div>
  );
}

export default Home;
EOL

cat > chatbot_app/frontend/components/ChatInterface.js <<EOL
import { useState, useEffect } from 'react';

function ChatInterface() {
  const [messages, setMessages] = useState([]);
  const [inputValue, setInputValue] = useState('');

  const sendMessage = async () => {
    if (inputValue.trim() === '') return;

    const newMessage = { text: inputValue, sender: 'user' };
    setMessages([...messages, newMessage]);
    setInputValue('');

    try {
      const response = await fetch('/api/chat', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ message: inputValue }),
      });

      if (!response.ok) {
        throw new Error(\`HTTP error! status: \${response.status}\`);
      }

      const data = await response.json();
      const botResponse = { text: data.response, sender: 'bot' };
      setMessages([...messages, newMessage, botResponse]);

    } catch (error) {
      console.error('Error sending message:', error);
      const errorResponse = { text: "Error communicating with the server.", sender: 'bot' };
      setMessages([...messages, newMessage, errorResponse]);
    }
  };

  return (
    <div style={{ maxWidth: '600px', margin: '20px auto', padding: '20px', border: '1px solid #ccc' }}>
      <div style={{ marginBottom: '10px' }}>
        {messages.map((message, index) => (
          <div
            key={index}
            style={{
              marginBottom: '5px',
              padding: '8px',
              borderRadius: '5px',
              backgroundColor: message.sender === 'user' ? '#DCF8C6' : '#ECE5DD',
              textAlign: message.sender === 'user' ? 'right' : 'left',
            }}
          >
            {message.text}
          </div>
        ))}
      </div>
      <div style={{ display: 'flex' }}>
        <input
          type="text"
          value={inputValue}
          onChange={(e) => setInputValue(e.target.value)}
          style={{ flexGrow: 1, padding: '8px', marginRight: '10px' }}
          onKeyPress={(event) => {
            if (event.key === 'Enter') {
              sendMessage();
            }
          }}
        />
        <button onClick={sendMessage} style={{ padding: '8px 15px', backgroundColor: '#4CAF50', color: 'white', border: 'none', cursor: 'pointer' }}>
          Send
        </button>
      </div>
    </div>
  );
}

export default ChatInterface;
EOL

cat > chatbot_app/frontend/pages/api/chat.js <<EOL
export default async function handler(req, res) {
  if (req.method === 'POST') {
    try {
      const response = await fetch('http://backend:5000/chat', {  // Backend service name in docker-compose
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(req.body),
      });

      if (!response.ok) {
        throw new Error(\`Backend error! status: \${response.status}\`);
      }

      const data = await response.json();
      res.status(200).json(data);

    } catch (error) {
      console.error('Error proxying to backend:', error);
      res.status(500).json({ error: 'Failed to communicate with the backend.' });
    }
  } else {
    res.status(405).json({ error: 'Method Not Allowed' });
  }
}
EOL

cat > chatbot_app/frontend/next.config.js <<EOL
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
}

module.exports = nextConfig
EOL

cat > chatbot_app/frontend/package.json <<EOL
{
  "name": "frontend",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "next": "13.x",
    "react": "18.x",
    "react-dom": "18.x"
  },
  "devDependencies": {
    "eslint": "8.x",
    "eslint-config-next": "13.x"
  }
}
EOL

cat > chatbot_app/backend/app.py <<EOL
from flask import Flask, request, jsonify
from flask_cors import CORS
from pymongo import MongoClient
from models import ChatMessage
import os

app = Flask(__name__)
CORS(app)  # Enable CORS for cross-origin requests

# MongoDB Configuration
mongo_uri = os.environ.get('MONGO_URI')
mongo_db_name = os.environ.get('MONGO_DB_NAME')

client = MongoClient(mongo_uri)
db = client[mongo_db_name]  # Access the specific database
messages_collection = db['messages']

@app.route('/chat', methods=['POST'])
def chat():
    try:
        data = request.get_json()
        user_query = data.get('message')

        # Simulate Chatbot Response (Replace with your actual chatbot logic)
        chatbot_response = generate_chatbot_response(user_query)

        # Save to MongoDB
        chat_message = ChatMessage(user_query=user_query, chatbot_response=chatbot_response)
        messages_collection.insert_one(chat_message.to_dict())

        return jsonify({'response': chatbot_response})

    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500  # Internal Server Error

def generate_chatbot_response(user_query):
    """
    Replace this with your actual chatbot integration (e.g., using a library like Transformers, Langchain, etc.)
    """
    if "hello" in user_query.lower():
        return "Hello there! How can I help you?"
    elif "goodbye" in user_query.lower():
        return "Goodbye! Have a great day."
    else:
        return f"I received your message: {user_query}. I'm a simple bot, but I'll try my best."


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')
EOL

cat > chatbot_app/backend/models.py <<EOL
class ChatMessage:
    def __init__(self, user_query, chatbot_response):
        self.user_query = user_query
        self.chatbot_response = chatbot_response

    def to_dict(self):
        return {
            'user_query': self.user_query,
            'chatbot_response': self.chatbot_response
        }
EOL

cat > chatbot_app/backend/requirements.txt <<EOL
Flask
Flask-CORS
pymongo
python-dotenv
EOL

cat > chatbot_app/docker-compose.yml <<EOL
version: "3.8"
services:
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    depends_on:
      - backend
    environment:
      - NEXT_PUBLIC_BACKEND_URL=http://backend:5000 # Important: Use the service name
    networks:
      - app-network

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    environment:
      - MONGO_URI=mongodb://mongodb:27017/
      - MONGO_DB_NAME=chatbot_db
    depends_on:
      - mongodb
    networks:
      - app-network

  mongodb:
    image: mongo:latest
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data:/data/db  # Persist data
    networks:
      - app-network

networks:
  app-network:
    driver: bridge

volumes:
  mongodb_data: #Named volume for MongoDB data persistence
EOL

cat > chatbot_app/.env <<EOL
MONGO_URI=mongodb://localhost:27017/
MONGO_DB_NAME=chatbot_db
EOL

cat > chatbot_app/frontend/Dockerfile <<EOL
FROM node:18-alpine AS builder

WORKDIR /app

COPY frontend/package*.json ./
RUN npm install

COPY frontend/. .

RUN npm run build

FROM nginx:alpine

COPY --from=builder /app/out /usr/share/nginx/html
COPY frontend/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
EOL

cat > chatbot_app/frontend/nginx.conf <<EOL
server {
    listen 80;
    server_name localhost;

    root /usr/share/nginx/html;
    index index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
EOL

cat > chatbot_app/backend/Dockerfile <<EOL
FROM python:3.9-slim-buster

WORKDIR /app

COPY backend/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY backend/. .

ENV FLASK_APP=app.py

CMD ["flask", "run", "--host", "0.0.0.0"]
EOL

# Create the zip file
zip -r chatbot_app.zip chatbot_app

# Clean up (optional)
#rm -rf chatbot_app
