server {
    listen      %ip%:%web_port%;
    server_name %domain_idn% %alias_idn%;

    root        %docroot%;
    index       index.php index.html index.htm;
    access_log  /var/log/nginx/domains/%domain%.log combined;
    access_log  /var/log/nginx/domains/%domain%.bytes bytes;
    error_log   /var/log/nginx/domains/%domain%.error.log error;

    # Define /poc
    location /poc {
        alias %home%/%user%/web/%domain%/public_html/migration/endpoints;

        location ~ \.php$ {
            fastcgi_param SCRIPT_FILENAME $request_filename;
            fastcgi_intercept_errors on;

            fastcgi_pass    %backend_lsnr%;
            fastcgi_index   index.php;
            include         /etc/nginx/fastcgi_params;
        }
    }

    location / {
        # Deny access to files
        location ~ (/xmlrpc.php|.htaccess|.htpasswd|.git) {
            deny all;
            access_log off;
            log_not_found off;
            return 444;
        }

        # Do not log access
        location ~ (/favicon.ico|/robots.txt) {
            log_not_found off;
            access_log off;
        }

        # Deny access to .php under wp-content and wp-includes
        location ~ (/wp-content|wp-includes) {
            location ~ \.php$ {
                    deny all;
                    access_log off;
                    log_not_found off;
                    return 444;
            }
        }

        # Protect wp-login from bruteforce attacks
        location ~ /wp-login.php {
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

        try_files $uri $uri/ /index.php?$args;

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

    include     %home%/%user%/conf/web/nginx.%domain%.conf*;
}