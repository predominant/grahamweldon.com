---
title: Nginx maps and geo
slug: "nginx-maps-and-geo"
date: 2019-06-11T00:00:00+09:00
highlight: false
draft: false
tags: ['habitat', 'nginx', 'maps', 'web', 'server']
---

Nginx is a truly powerful, efficient, configurable web server. I've been using it for over 12 years. But for the longest time, I've been relying on simple configuration and basic rule sets to get by. While that's no problem, I wanted to share what I have learned recently with `map` and `geo` usage in Nginx configuration.

I feel the Nginx documentation is loosely sufficient, but could do with some more examples. The [map module][nginx-map] explains only a couple of examples and some important information around wildcards and matching. The [geo module][nginx-geo] is a little better, but documenting a couple of use cases here will help me, and maybe others wanting to delve into more complex Nginx configuration.

## The `map` module

As explained in the [documentation for the map module][nginx-map], it provides three directives:

* `map`
* `map_hash_bucket_size`
* `map_hash_max_size`

The `map` directive is extremely flexible and powerful. It allows you to set the value of a variable based on another. Think of it like a `case` statement in your favourite programming language. After reading the documentation, I felt that explaining its using was better done with this approach:

```text
map <InputValue> <OutputValue> {
  default <DefaultReturnValue>;

  <Match1> <Match1ReturnValue>;
  <Match2> <Match2ReturnValue>;
}
```

`InputValue` is the value being checked / matched against in this `map`. `InputValue` could be a string, or some other variable:

Plain text input value of `"Hello"`:

```text
map "Hello" $foo {
  default 0;
}
```

This is a naive map that doesn't really have any functional use, however there are cases where you have your Nginx configuration generated by a system, where a static text value being input would make sense. More on this later.

Using a variable defined by Nginx (`$host`):

```text
map $host $foo {
  default 0;

  "grahamweldon.com" 1;
  "slavitica.net" 2;
}
```

This is more interesting. Based on the [`$host` variable](nginx-host-variable) (which is the `server_name` that is currently being accessed) a different value is output from this map: `1` if grahamweldon.com is being accessed, `2` if slavitica.net is being accessed, and `0` in every other case.

These `OutputValue`s that are defined as the second variable in a map, are able to be referenced from anywhere within your Nginx `http` block.

For example, the following map defines a path to content, based on the `$host` variable:

```text
map $host $site_content {
  default "public";

  "grahamweldon.com" "grahamweldon";
  "slavitica.net" "slavitica";
}
```

With this map in place, we could setup a `server` such as this:

```text
http {
  [ ... ]

  server {
    listen 80 default_server;
    server_name _;
    location / {
      root /usr/local/websites/$site_content;
      try_files $uri index.html =404;
    }
  }
}
```

This `server` block defines itself as the default server, accepts any server name, listens on port `80` and serves a root directory based on the `$host` name via the `map` defined earlier. With a simple map in place we have a simple scalable, and easy to read virtual-hosting configuration!

Where I have found this to be extremely useful is in the case of conditional logging. You may have specific rules defining when to log information, or what information to log. On a recent project at [work][rakuten] I use the `map` directive to enable/disable logging to a specific "alert" log file based on certain rules:

```text
map $http_x_rakuten_alert $alert {
  default 0;

  "~*^ALERT$" 1;
}
```

This `InputValue` uses the HTTP Headers, specifically `X-Rakuten-Alert` (not the actual header we're using, this is just an example) to determine if alerting should be enabled or disabled. Alerting in this case is done by logging to a log file ending with `_alert.log` which is picked up by filebeat, and shipped to other systems.

The `location` block defines a log file with custom conditions based on this map:

```text
server {
  listen 80 default_server;
  server_name _;
  location / {
    access_log /var/log/web_alert.log custom if=$alert;
  }
}
```

That last piece on the `access_log` line: `if=$alert` causes the map to be looked up with the current request information, and since we're returning either `0` or `1`, this is used to determine if logging should be done for that request.

## Map return values

An interesting point to note is that Nginx considers all map values returned to be "truthy" if they are non-zero or non-empty.

That is, `0` and `""` are false values, if being passed to a conditional check like `if=`.

## The `geo` module

The [`geo` module][nginx-geo] is just as interesting. Its behaviour is the same in terms of input and output variables, but this time we can do complicated lookups based on IP address information. For example, we can perform access logging only if the request is NOT from the local network:

```text
geo $remote_addr $log_request {
  default 1;
  
  10.0.0.0/8 0;
}
```

We could then reference this `$log_request` variable in a `location` block, like so:

```text
location {
  root /some/path;
  access_log /var/log/access.log combined if=$log_request;
}
```

Any request coming from the `10.0.0.0/8` CIDR will not be logged.

Sometimes you don't have full CIDR ranges you can specify, you might have to list distinct ranges. This can be done by starting the `geo` block with the `ranges` declaration:

```text
geo $remote_addr $log_request {
  ranges;
  default 1;

  10.0.0.0-10.2.0.12 0;
  10.2.8.103-10.2.8.254 0;
}
```

## Summary

These examples give you a glimpse of the possibilities with the `map` and `geo` commands, and hopefully will help you reduce complexity, improve readability of rule sets, and ideally: Replace all your `if` statements in your Nginx configuration!

Let me know how you're configuring Nginx, and if this post helped you!

[nginx-map]: http://nginx.org/en/docs/http/ngx_http_map_module.html
[nginx-geo]: http://nginx.org/en/docs/http/ngx_http_geo_module.html
[nginx-host-variable]: http://nginx.org/en/docs/http/ngx_http_core_module.html#var_host
[rakuten]: https://global.rakuten.com/corp/about/