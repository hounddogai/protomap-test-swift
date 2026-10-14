import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Patients_V1_ListMedicalRecordWorkflowsRequest {
    static func forCareInboxNotificationEndpointSubscribeCareInboxUpdates1(
        _ input: Acme_Patientapp_V1_SubscribeCareInboxUpdatesRequest
    ) -> Self {
        Acme_Patients_V1_ListMedicalRecordWorkflowsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patients_V1_ListMedicalRecordWorkflowsRequest.Filter.with {
                $0.createdAfter = input.context.deadline
                $0.labels = input.details.variables
                $0.ownerID = input.details.templateID
            }
        }
    }
}
