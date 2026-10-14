import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Patientapp_V1_NotifyCareInboxWatchersRequest {
    static func forCareInboxQueryEndpointSummarizeCareInboxes3(
        _ input: Acme_Patientapp_V1_SummarizeCareInboxesRequest,
        reply0: Acme_Careplans_V1_CancelCareGoalWorkflowResponse,
        reply2: Acme_Patients_V1_DelegateMedicalRecordApprovalResponse
    ) -> Self {
        Acme_Patientapp_V1_NotifyCareInboxWatchersRequest.with {
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_NotifyCareInboxWatchersRequest.Details.with {
                $0.recipient = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply2.medicalRecord.counterparty.email
                    $0.name = reply0.careGoal.requester.name
                    $0.phone = reply0.careGoal.requester.phone
                    $0.preferredChannel = reply0.careGoal.requester.preferredChannel
                }
            }
        }
    }
}
