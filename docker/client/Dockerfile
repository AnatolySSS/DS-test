# Базовый образ для разработки (hot-reload)
FROM node AS dev

WORKDIR /app

COPY ./client/package*.json ./

RUN npm install

COPY . .

EXPOSE 3000

# Базовый образ для продакшена
FROM node AS prod

WORKDIR /app

COPY ./client/package*.json ./

RUN npm install --only=production

COPY . .