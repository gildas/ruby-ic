module Ic
  # This module contains the security rights used when querying the CIC configuration.
  module RightsFilter
    VIEW = "view"
    ADMIN = "admin"
    LOGGEDINUSER = "loggedInUser"
    CHANGEUSERSTATUS = "changeUserStatus"
    RECORDUSERQUEUE = "recordUserQueue"
    LISTENUSERQUEUE = "listenUserQueue"
    JOINUSERQUEUE = "joinUserQueue"
    COACHUSERQUEUE = "coachUserQueue"
    PICKUPUSERQUEUE = "pickupUserQueue"
    TRANSFERUSERQUEUE = "transferUserQueue"
    DISCONNECTUSERQUEUE = "disconnectUserQueue"
    VIEWINDIVIDUALSTATISTICS = "viewIndividualStatistics"
    VIEWUSERINTERACTIONHISTORY = "viewUserInteractionHistory"
    MUTEUSERQUEUE = "muteUserQueue"
    HOLDUSERQUEUE = "holdUserQueue"
    PREVIEWEMAILUSERQUEUE = "previewEmailUserQueue"
  end
end
