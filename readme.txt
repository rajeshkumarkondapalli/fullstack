How to Use the Script:

Save: Save the script above to a file named create_chatbot_zip.sh.

Make Executable: Run chmod +x create_chatbot_zip.sh in your terminal.

Execute: Run ./create_chatbot_zip.sh. This will create a directory chatbot_app, populate it with all the necessary files, then create a zip archive called chatbot_app.zip in the same directory where the script is located.

Remove the directory

rm -rf chatbot_app


Now you will have all the files in the root of your folder and chatbot_app.zip
You can then download the chatbot_app.zip file.


chatbot_app/
├── frontend/          # Next.js Frontend
│   ├── pages/
│   │   └── index.js
│   ├── components/
│   │   └── ChatInterface.js
│   ├── next.config.js
│   ├── package.json
│   └── ...
├── backend/           # Python (Flask) Backend
│   ├── app.py
│   ├── requirements.txt
│   └── models.py      # Database models
├── docker-compose.yml # Docker Compose file
├── .env              # environment files to store connection strings and other keys
