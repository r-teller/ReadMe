variable "host_project_id" {
    type = string
    description = "Host Project id of the project that holds the network."
}


variable "target_mappings" {
    # type = list(object({
    #     folder_ids = list(number),
    #     project_ids = list(string),
    #     subnet_match = object({
    #       subnetwork = optional(object({
    #         regex = string
    #       })),
    #       region = optional(object({
    #         regex = string
    #       })),          
    #       network = optional(object({
    #         regex = string
    #       }))
    #     }),
    #     subnet_list = list(string)
    #   })
    # )
}