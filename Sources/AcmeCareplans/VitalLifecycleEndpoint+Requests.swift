import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Appointments_V1_CountProvidersRequest {
    static func forVitalLifecycleEndpointTerminateVital1(
        _ input: Acme_Careplans_V1_TerminateVitalRequest,
        reply0: Acme_Notifications_V1_FindNotificationsResponse
    ) -> Self {
        Acme_Appointments_V1_CountProvidersRequest.with {
            $0.context = input.context
            $0.filter = Acme_Appointments_V1_CountProvidersRequest.Filter.with {
                $0.createdAfter = input.details.effectiveAt
                $0.labels = reply0.result.details
                $0.ownerID = input.details.newOwner.userID
            }
        }
    }
}
