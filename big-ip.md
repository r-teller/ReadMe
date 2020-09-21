
## iRule to log mgmt traffic
```bash
when HTTP_REQUEST {
    log local0. "([IP::client_addr]) - [HTTP::method] [HTTP::path]"

    log local0. "([IP::client_addr]) - [HTTP::header names]"
    log local0. "([IP::client_addr]) - Auth --> [HTTP::header Authorization]"
    if {[HTTP::method] equals "POST"}{
        # Get the content length so we can request the data to be processed in the HTTP_REQUEST_DATA event.
        if {[HTTP::header exists "Content-Length"]}{
            set content_length [HTTP::header "Content-Length"]
        } else {
            set content_length 0
        }
        if { $content_length > 0} {
            HTTP::collect $content_length
        }
    }


    
    node 127.0.0.1 8443
}

when HTTP_REQUEST_DATA {
    log local0. "([IP::client_addr]) - [HTTP::payload]"
    HTTP::release
}

when HTTP_RESPONSE {
    log local0. "([IP::client_addr]) - [HTTP::status]"
    set content_length [HTTP::header "Content-Length"]
    HTTP::collect $content_length
}

when HTTP_RESPONSE_DATA {
    log local0. "([IP::client_addr]) - [HTTP::payload]"
    HTTP::release
}
```
