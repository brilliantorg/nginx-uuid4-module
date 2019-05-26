/* (C) 2015 Cybozu.  All rights reserved. */

#include <ngx_config.h>
#include <ngx_core.h>
#include <ngx_http.h>


static char *ngx_http_uuid4(ngx_conf_t *cf, ngx_command_t *cmd, void *conf);


static ngx_command_t  ngx_http_uuid4_commands[] = {

    { ngx_string("uuid4"),
      NGX_HTTP_MAIN_CONF|NGX_HTTP_SRV_CONF|NGX_HTTP_LOC_CONF|NGX_CONF_TAKE1,
      ngx_http_uuid4,
      NGX_HTTP_LOC_CONF_OFFSET,
      0,
      NULL },

    ngx_null_command
};


static ngx_http_module_t  ngx_http_uuid4_module_ctx = {
    NULL,                       /* preconfiguration */
    NULL,                       /* postconfiguration */

    NULL,                       /* create main configuration */
    NULL,                       /* init main configuration */

    NULL,                       /* create server configuration */
    NULL,                       /* merge server configuration */

    NULL,                       /* create location configuration */
    NULL                        /* merge location configuration */
};


ngx_module_t  ngx_http_uuid4_module = {
    NGX_MODULE_V1,
    &ngx_http_uuid4_module_ctx,            /* module context */
    ngx_http_uuid4_commands,               /* module directives */
    NGX_HTTP_MODULE,                       /* module type */
    NULL,                                  /* init master */
    NULL,                                  /* init module */
    NULL,                                  /* init process */
    NULL,                                  /* init thread */
    NULL,                                  /* exit thread */
    NULL,                                  /* exit process */
    NULL,                                  /* exit master */
    NGX_MODULE_V1_PADDING
};


static ngx_int_t
ngx_http_uuid4_variable(ngx_http_request_t *r, ngx_http_variable_value_t *v,
    uintptr_t data)
{
    static const size_t UUID_STR_LENGTH = 36;
    static FILE        *urandom_fh;
    static uint64_t     buf[2];

    if (!urandom_fh) {
        urandom_fh = fopen("/dev/urandom", "r");
        if (urandom_fh == NULL) {
            ngx_log_error(NGX_LOG_ERR, r->connection->log, 0,
                        "failed to open /dev/urandom");
            return NGX_ERROR;
        }
    }

    size_t n = fread(buf, sizeof(uint64_t), 2, urandom_fh);
    if (n < 2) {
        ngx_log_error(NGX_LOG_ERR, r->connection->log, 0,
                      "failed to read /dev/urandom");
        fclose(urandom_fh);
        urandom_fh = NULL;
        return NGX_ERROR;
    }

    uint64_t upper = buf[0];
    uint64_t lower = buf[1];

    // Adjust certain bits according to RFC 4122 section 4.4 as follows:
    // set the four most significant bits of the 7th byte to 0100'B, so the high nibble is "4"
    upper &= ~((1ULL << 12) | (1ULL << 13) | (1ULL << 15));
    upper |= (1ULL << 14);

    // set the two most significant bits of the 9th byte to 10'B, so the high nibble will be one
    // of "8", "9", "A", or "B"
    lower &= ~(1ULL << 62);
    lower |= (1ULL << 63);

    v->len = UUID_STR_LENGTH;
    v->data = ngx_palloc(r->pool, UUID_STR_LENGTH);
    if (v->data == NULL) {
        *v = ngx_http_variable_null_value;
        return NGX_OK;
    }
    ngx_snprintf(v->data, UUID_STR_LENGTH, "%08uxL-%04uxL-%04uxL-%04uxL-%012uxL",
        upper >> 32, (upper >> 16) & 0xFFFFULL, upper & 0xFFFFULL,
        lower >> 48, lower & 0xFFFFFFFFFFFFULL);
    v->valid = 1;
    v->no_cacheable = 0;
    v->not_found = 0;

    return NGX_OK;
}


static char *
ngx_http_uuid4(ngx_conf_t *cf, ngx_command_t *cmd, void *conf)
{
    ngx_str_t           *value;
    ngx_http_variable_t *v;
    ngx_int_t            index;

    value = cf->args->elts;
    if (value[1].data[0] != '$') {
        ngx_conf_log_error(NGX_LOG_EMERG, cf, 0,
                           "invalid variable name \"%V\"", &value[1]);
        return NGX_CONF_ERROR;
    }

    value[1].len--;
    value[1].data++;

    v = ngx_http_add_variable(cf, &value[1], NGX_HTTP_VAR_CHANGEABLE);
    if (v == NULL) {
        return NGX_CONF_ERROR;
    }

    index = ngx_http_get_variable_index(cf, &value[1]);
    if (index == NGX_ERROR) {
        return NGX_CONF_ERROR;
    }

    v->get_handler = ngx_http_uuid4_variable;

    return NGX_CONF_OK;
}
