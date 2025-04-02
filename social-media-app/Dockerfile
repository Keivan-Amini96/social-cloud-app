FROM nginx:latest

# Install curl for health checks
RUN apt-get update && apt-get install -y curl

# Copy frontend files
COPY public/ /usr/share/nginx/html/

# Add API proxy config
RUN echo 'server { \
  location /api { \
    proxy_pass http://backend-service:3000; \
    proxy_set_header Host $host; \
    proxy_set_header X-Real-IP $remote_addr; \
  } \
}' > /etc/nginx/conf.d/api-proxy.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
