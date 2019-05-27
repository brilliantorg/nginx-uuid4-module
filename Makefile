#
# This is a makefile to build our custom nginx. In order to build and install:
# 
#     1. sudo apt-get install build-essential zlib1g-dev libpcre3 libpcre3-dev unzip
#     2. edit the version numbers
#     3. make
#     4. make install
#     5. make clean
#
NGINX_VER = 1.14.2
OPENSSL_VER = 1.1.1a

all: clean download unpack apply_patch build


all_install: all install clean


clean:
	rm -f nginx-$(NGINX_VER).tar.gz
	rm -f openssl-$(OPENSSL_VER).tar.gz
	rm -fr nginx-$(NGINX_VER)
	rm -fr openssl-$(OPENSSL_VER)
	rm -fr nginx-uuid4-module


download:
	wget http://nginx.org/download/nginx-$(NGINX_VER).tar.gz
	wget https://www.openssl.org/source/openssl-$(OPENSSL_VER).tar.gz
	git clone https://github.com/brilliantorg/nginx-uuid4-module.git

unpack:
	tar --no-same-owner -xzf nginx-$(NGINX_VER).tar.gz
	tar --no-same-owner -xzf openssl-$(OPENSSL_VER).tar.gz


apply_patch:
	cd nginx-$(NGINX_VER); patch -p1 < ../ssl-bufsize.patch


#
# difference from the ubuntu team configure flags are:
# 
# - specify user
# - specify group
# - use different prefix
# - use different modules path
# - statically link openssl
# - do not add dynamic modules: (http-auth-pam, http-dav-ext, etc.)
#
build:
	cd nginx-$(NGINX_VER); ./configure \
	    --prefix=/usr/local \
	    --modules-path=/usr/local/lib/nginx/modules \
	    --user=www-data \
	    --group=www-data \
	    --conf-path=/etc/nginx/nginx.conf \
	    --http-log-path=/var/log/nginx/access.log \
	    --error-log-path=/var/log/nginx/error.log \
	    --lock-path=/var/lock/nginx.lock \
	    --pid-path=/run/nginx.pid \
	    --http-client-body-temp-path=/var/lib/nginx/body \
	    --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
	    --http-proxy-temp-path=/var/lib/nginx/proxy \
	    --http-scgi-temp-path=/var/lib/nginx/scgi \
	    --http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
	    --with-debug \
	    --with-http_addition_module \
	    --with-http_auth_request_module \
	    --with-http_dav_module \
	    --with-http_gunzip_module \
	    --with-http_gzip_static_module \
	    --with-http_image_filter_module=dynamic \
	    --with-http_realip_module \
	    --with-http_slice_module \
	    --with-http_ssl_module \
	    --with-http_stub_status_module \
	    --with-http_sub_module \
	    --with-http_v2_module \
	    --with-http_xslt_module=dynamic \
	    --with-mail=dynamic \
	    --with-mail_ssl_module \
	    --with-openssl=../openssl-$(OPENSSL_VER) \
	    --with-pcre-jit \
	    --with-stream=dynamic \
	    --with-stream_ssl_module \
	    --with-stream_ssl_preread_module \
	    --with-threads \
	    --with-http_geoip_module=dynamic \
	    --add-dynamic-module=../nginx-uuid4-module
	make -C nginx-$(NGINX_VER)


install:
	make -C nginx-$(NGINX_VER) install
