import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Notifications_V1_SearchNotificationsRequest {
    static func forPatientSyncEndpointSyncPatients3(
        _ input: Acme_Patients_V1_SyncPatientsRequest,
        reply0: Acme_Prescriptions_V1_ShareRefillReportResponse
    ) -> Self {
        Acme_Notifications_V1_SearchNotificationsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Notifications_V1_SearchNotificationsRequest.Filter.with {
                $0.createdAfter = reply0.refill.audit.updatedAt
                $0.region = input.patient.primaryAddress.region
            }
        }
    }
}
