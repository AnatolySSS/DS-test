FROM node AS dev

WORKDIR /app

COPY ./server/package*.json ./

RUN npm install

COPY . .

EXPOSE 80

FROM node AS prod

WORKDIR /app

COPY ./server/package*.json ./

RUN npm install --only=production

COPY . .

EXPOSE 80