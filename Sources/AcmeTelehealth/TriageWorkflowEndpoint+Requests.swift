import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Patients_V1_ValidatePatientRequest {
    static func forTriageWorkflowEndpointStartTriageWorkflow0(
        _ input: Acme_Telehealth_V1_StartTriageWorkflowRequest
    ) -> Self {
        Acme_Patients_V1_ValidatePatientRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedBy = input.triage.audit.updatedBy
                }
            }
        }
    }
}
