
A small [Janet](https://janet-lang.org/) library to make reading and writing HTTP/1.1 streams easier. With Janet's built-in [net library](https://janet-lang.org/api/net.html), you can write terse HTTP code without a large framework.

## Install

```
jpm install https://github.com/m7andrew/read-write-http
```

## Examples

```clojure
(use http)

(def response
  {:status 200
   :headers {"Content-Type" "text/plain"}
   :body "Hello World"})

(defn handler [stream]
  (pp (read/request stream))
  (write/response stream response)
  (net/close stream))

(net/server "localhost" 8000 handler)
```
> Minimal server

```clojure
(use http)

(def request
  {:method "GET"
   :uri "/imghp"
   :headers {"Host" "www.google.com"}})

(def stream (net/connect "www.google.com" 80))
(write/request stream request)
(pp (read/response stream))
(net/close stream)
```
> Send a request.

## Functions

* [Read Request](#read-request)
* [Read Response](#read-response)
* [Write Request](#write-request)
* [Write Response](#write-response)

### Read Request

```clojure
(read/request stream)
```

Reads a stream for a request. Returns a request as a struct with the following fields:

* `:method` string, the HTTP method.
* `:path` string, the URI path.
* `:query` struct, the URI query paramaters. If no query, field is omitted.
* `:headers` struct, the HTTP headers.
* `:body` string, the request body. If no body, field is omitted.

Returns nil if no request could be read.

### Read Response

```clojure
(read/response stream)
```

Reads a stream for a response. Returns a response as a struct with the following fields:

* `:status` number, the HTTP status code.
* `:headers` struct, the HTTP headers.
* `:body` string, the HTTP body. If no body, field is omitted.

Returns nil if no response could be read.

### Write Response

```clojure
(write/response stream response)
```

Write a response to a stream where `response` is a struct or table with the following fields:

* `:status` number, the HTTP status code. Optional. Defaults to `200`
* `:headers` struct or table, the HTTP headers. Optional. `"Content-Length"` is automatically set.
* `:body` string, the HTTP body. Optional.

Returns nil, or raises an error if the write failed.

### Write Request

```clojure
(write/request stream request)
```

Write a request to a stream where `request` is a struct or table with the following fields:

* `:method` string, the HTTP method. Optional. Defaults to `"GET"`.
* `:uri` string, the HTTP URI. Optional. Defaults to `"/"`.
* `:headers` struct or table, the HTTP headers. `"Host"` is required.
* `:body` string, the HTTP body. Optional.

Returns nil, or raises an error if the write failed.
