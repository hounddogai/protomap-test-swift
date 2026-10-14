import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Patients_V1_CheckPatientEligibilityRequest {
    static func forVisitNoteWorkflowEndpointResumeVisitNoteWorkflow0(
        _ input: Acme_Telehealth_V1_ResumeVisitNoteWorkflowRequest
    ) -> Self {
        Acme_Patients_V1_CheckPatientEligibilityRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.visitNote.billingAddress.region
                }
            }
        }
    }
}
