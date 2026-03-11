FROM nginx:alpine

RUN rm /etc/nginx/conf.d/default.conf

COPY default.conf /etc/nginx/conf.d/default.conf

# Dar permisos al usuario nginx sobre los directorios que necesita
RUN chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    chown -R nginx:nginx /etc/nginx/conf.d && \
    touch /var/run/nginx.pid && \
    chown nginx:nginx /var/run/nginx.pid

# El proceso master de nginx necesita root para bindear el puerto 80,
# pero los workers correrán como el usuario 'nginx' (definido en nginx.conf)
USER nginx