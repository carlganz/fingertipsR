#' Live profiles
#'
#' Outputs a data frame of live profiles that data are available for in
#' Fingertips \url{http://fingertips.phe.org.uk/}
#' @return A data frame of live profile ids and names along with their domain
#'   names and ids.
#' @inheritParams indicators
#' @param ProfileName Character vector, full name of profile(s)
#' @examples
#' \dontrun{
#' # Returns a complete data frame of domains and their profiles
#' profiles()}
#'
#' # Returns a data frame of all of the domains in the Public Health Outcomes Framework
#' profiles(ProfileName = "Public Health Outcomes Framework")
#' @import dplyr
#' @importFrom jsonlite fromJSON
#' @importFrom httr GET content set_config config
#' @importFrom data.table rbindlist
#' @family lookup functions
#' @seealso \code{\link{area_types}} for area type  and their parent mappings,
#'   \code{\link{indicators}} for indicator lookups,
#'   \code{\link{indicator_metadata}} for indicator metadata and
#'   \code{\link{deprivation_decile}} for deprivation decile lookups
#' @export

profiles <- function(ProfileID = NULL, ProfileName = NULL) {
        path <- "https://fingertips.phe.org.uk/api/"
        set_config(config(ssl_verifypeer = 0L))
        profiles <- paste0(path,"profiles") %>%
                GET %>%
                content("text") %>%
                fromJSON
        idname <- profiles[,c("Id", "Name")]

        profiles <- lapply(profiles$GroupIds, data.frame)
        names(profiles) <- idname$Id
        profiles <- rbindlist(profiles,
                              use.names = TRUE,
                              fill = TRUE,
                              idcol = "profiles") %>%
                mutate(profiles = as.numeric(profiles)) %>%
                left_join(idname, by = c("profiles" = "Id"))
        names(profiles) <- c("ID", "groupid", "Name")
        profiles <- profiles[, c("ID", "Name", "groupid")]
        if (!is.null(ProfileID)) {
                profiles <- filter(profiles, ID %in% ProfileID)
                if (nrow(profiles) == 0){
                        stop("ProfileID(s) are not in the list of profile IDs. Re-run the function without any inputs to see all possible IDs.")
                }
        } else if (!is.null(ProfileName)) {
                profiles <- filter(profiles, Name %in% ProfileName)
                if (nrow(profiles) == 0){
                        stop("Profile names are not in the list of profile names. Re-run the function without any inputs to see all possible names.")
                }
        }
        groupDescriptions <- data.frame()
        for (i in unique(profiles$ID)){
                query <- paste0(path,"group_metadata?group_ids=",
                                paste(profiles$groupid[profiles$ID == i],
                                      collapse = "%2C"))
                groupDescriptions <- rbind(query %>% GET %>% content("text") %>% fromJSON(), groupDescriptions)
        }
        groupDescriptions <- groupDescriptions %>%
                select(Id, Name)
        profiles <- rename(profiles,ProfileID = ID,ProfileName = Name, DomainID = groupid) %>%
                left_join(groupDescriptions, by = c("DomainID" = "Id")) %>%
                rename(DomainName = Name)
        return(profiles)
}
