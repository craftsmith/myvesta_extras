server {
    listen      %ip%:%web_port%;
    server_name %domain_idn% %alias_idn%;

    root        %docroot%;
    index       index.php index.html index.htm;
    access_log  /var/log/nginx/domains/%domain%.log combined;
    access_log  /var/log/nginx/domains/%domain%.bytes bytes;
    error_log   /var/log/nginx/domains/%domain%.error.log error;

    location = (/favicon.ico|/robots.txt) {
        log_not_found off;
        access_log off;
    }

    # protect wp
    location ^~ (/xmlrpc.php|/wp-includes) {
        deny all;
        access_log off;
        log_not_found off;
        return 444;
    }
    # end protect wp

    # protect wp-snapshots
    location /wp-snapshots {

        auth_basic "Restricted";
        auth_basic_user_file /etc/nginx/.htpasswd;
    }
    # end protect wp-snapshots

    # protect wp-admin
    location ^~ (/wp-admin|/wp/wp-admin|/wp-login.php|/wp/wp-login.php) {

        location ~ admin-ajax.php {
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            if (!-f $document_root$fastcgi_script_name) {
                return  404;
            }

            fastcgi_pass    %backend_lsnr%;
            fastcgi_index   index.php;
            include         /etc/nginx/fastcgi_params;
        }

        location ~ [^/]\.php(/|$) {

            auth_basic "Restricted";
            auth_basic_user_file /etc/nginx/.htpasswd;

            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            if (!-f $document_root$fastcgi_script_name) {
                return  404;
            }

            fastcgi_pass    %backend_lsnr%;
            fastcgi_index   index.php;
            include         /etc/nginx/fastcgi_params;
        }
    }
    # end protect wp-admin

    location / {
        try_files $uri $uri/ /index.php?$args;

        location ~* ^.+\.(jpeg|jpg|png|gif|bmp|ico|svg|css|js)$ {
            expires     max;
        }

        location ~ [^/]\.php(/|$) {
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            if (!-f $document_root$fastcgi_script_name) {
                return  404;
            }

            fastcgi_pass    %backend_lsnr%;
            fastcgi_index   index.php;
            include         /etc/nginx/fastcgi_params;
        }
    }

    error_page  403 /error/404.html;
    error_page  404 /error/404.html;
    error_page  500 502 503 504 /error/50x.html;

    location /error/ {
        alias   %home%/%user%/web/%domain%/document_errors/;
    }

    location ~* "/\.(htaccess|htpasswd)$" {
        deny    all;
        return  404;
    }

    location /vstats/ {
        alias   %home%/%user%/web/%domain%/stats/;
        include %home%/%user%/conf/web/%domain%.auth*;
    }

    include     /etc/nginx/conf.d/phpmyadmin.inc*;
    include     /etc/nginx/conf.d/phppgadmin.inc*;
    include     /etc/nginx/conf.d/webmail.inc*;

    include     %home%/%user%/conf/web/nginx.%domain%.conf*;
}