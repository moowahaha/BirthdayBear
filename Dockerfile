FROM nginx:alpine

# Cloud Run forwards traffic to whatever port the container listens on.
# nginx defaults to 80; we override with our own config that binds 8080
# (Cloud Run's default $PORT) and adds sensible cache headers.
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Static site
COPY index.html /usr/share/nginx/html/
COPY assets /usr/share/nginx/html/assets/

EXPOSE 8080
