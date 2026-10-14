import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Patientapp_V1_PausePatientHomeWorkflowRequest {
    static func forCareInboxWorkflowEndpointAdvanceCareInboxWorkflow1(
        _ input: Acme_Patientapp_V1_AdvanceCareInboxWorkflowRequest
    ) -> Self {
        Acme_Patientapp_V1_PausePatientHomeWorkflowRequest.with {
            $0.context = input.context
            $0.patientHome = Acme_Patientapp_V1_PatientHome.with {
                $0.customer = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.careInbox.counterparty.displayName
                }
            }
        }
    }
}
