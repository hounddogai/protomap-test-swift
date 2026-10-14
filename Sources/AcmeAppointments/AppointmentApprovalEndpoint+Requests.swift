import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Appointments_V1_BrowseProvidersRequest {
    static func forAppointmentApprovalEndpointSubmitAppointment0(
        _ input: Acme_Appointments_V1_SubmitAppointmentRequest
    ) -> Self {
        Acme_Appointments_V1_BrowseProvidersRequest.with {
            $0.context = input.context
            $0.filter = Acme_Appointments_V1_BrowseProvidersRequest.Filter.with {
                $0.createdAfter = input.appointment.audit.createdAt
                $0.ownerID = input.details.approver.userID
                $0.region = input.appointment.location.region
            }
        }
    }
}
