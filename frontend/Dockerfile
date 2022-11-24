FROM node:alpine3.15
WORKDIR /app
COPY . .
RUN npm install
RUN npm ci
EXPOSE 3000
CMD [ "npm", "start"]