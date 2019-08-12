## Build
FROM beevelop/ionic AS ionic
ARG BUILD_ENV

# Create app directory
WORKDIR /usr/src/app
# Install app dependencies
# A wildcard is used to ensure both package.json AND package-lock.json are copied
# where available (npm@5+)
COPY package*.json ./
RUN npm ci
# Bundle app source
COPY . .
RUN if [ "$BUILD_ENV" = "development" ]; \
	then ionic build;  \
	else ionic build --prod; \
	fi

## Run 
FROM nginx:alpine
#COPY www /usr/share/nginx/html
COPY --from=ionic  /usr/src/app/www /usr/share/nginx/html
