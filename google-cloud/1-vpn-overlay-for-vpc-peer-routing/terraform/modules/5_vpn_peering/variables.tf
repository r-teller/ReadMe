variable "networks" {
    type = object({
        first = object({
            network = string,
            name = string
            project_id = string,
            region = string,
            advertised_networks = map(string)
        }),        
        second = object({
            network = string,
            name = string,
            project_id = string,
            region = string,
            advertised_networks = map(string)
        })
    })
}
