Docker PHP-FPM 7.2 & Nginx 1.14 on Alpine Linux
==============================================

Usage
-----

Pull/Clone source :

    git clone https://github.com/eratechid/docker-alpine-nginx-php7.git

Built docker image :

    docker build -t docker-alpine-nginx-php7 --build-arg NEW_RELIC_LICENSE_KEY=XXX --build-arg APP_NAME=MYAPPS .
    
Run docker image :

    docker run docker-alpine-nginx-php7
