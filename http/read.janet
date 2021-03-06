(import url)

(def- max-size 8192)

(def- $request
  (peg/compile
    ~{:main
        (sequence :method " " :uri " HTTP/1.1" :crlf :headers :crlf)
      :method
        (sequence (constant :method) (capture (to " ")))
      :uri
        {:main (sequence :path (opt :query) (opt :frag))
         :hex
           {:main (sequence "%" :hexd :hexd)
            :hexd (choice :d (range "af") (range "AF"))}
         :path
           {:main  (sequence (constant :path) (cmt (capture :root) ,url/unescape))
            :root  (some (sequence "/" (any :valid)))
            :valid (choice :w :hex (set "-._~!$&'()*+,;=:@"))}
         :query
           {:main  (sequence "?" (constant :query) (group :pairs))
            :pairs (sequence :pair (any (sequence "&" :pair)))
            :pair  (sequence (cmt (capture :valid) ,url/unescape) "=" (cmt (capture :valid) ,url/unescape))
            :valid (any (choice :w :hex (set "-._~!$'()*+,;:@/?")))}
         :frag
           (sequence "#" (to " "))}
      :headers
        {:main (sequence (constant :headers) (group (some :pair)))
         :pair (sequence (capture (to ": ")) ": " (capture (to :crlf)) :crlf)}
      :crlf
        "\r\n"}))

(def- $response
  (peg/compile
    ~{:main
        (sequence "HTTP/1.1 " :status :crlf :headers :crlf)
      :status
        (sequence (constant :status) (cmt (capture 3) ,scan-number) (to :crlf))
      :headers
        {:main (sequence (constant :headers) (group (some :pair)))
         :pair (sequence (capture (to ": ")) ": " (capture (to :crlf)) :crlf)}
      :crlf
        "\r\n"}))

(defn- array/zip [arr]
  (postwalk (fn [x] (if (array? x) (table ;x) x)) arr))

(defn- head-end? [http]
  (string/has-suffix? "\r\n\r\n" http))

(defn- read-stream [stream]
  (def http @"")
  (var size 0)
  (while (and (< size max-size) (not (head-end? http)))
    (net/read stream 1 http)
    (++ size))
  (string http))

(defn- parse [pattern stream]
  (when-let [http  (read-stream stream)
             http  (array/zip (peg/match pattern http))]
    (if-let [heads (get http :headers)
             size  (get heads "Content-Length")
             size  (scan-number size)]
      (put http :body (string (net/read stream size)))
      http)))

(defn request [stream]
  (freeze (parse $request stream)))

(defn response [stream]
  (freeze (parse $response stream)))
