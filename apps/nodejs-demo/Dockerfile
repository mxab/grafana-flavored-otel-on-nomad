FROM node:22.13.1-alpine

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm install

COPY main.js .

EXPOSE 3000
CMD ["node", "main.js"]