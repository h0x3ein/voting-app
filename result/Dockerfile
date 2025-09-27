FROM node:20.16-alpine3.19 


WORKDIR /build

COPY package*.json ./

RUN npm install --production

COPY . .

EXPOSE 5000

CMD ["npm", "start"]