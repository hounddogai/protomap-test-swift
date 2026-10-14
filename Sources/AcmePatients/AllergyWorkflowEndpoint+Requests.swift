import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Patients_V1_SimulateAllergyRequest {
    static func forAllergyWorkflowEndpointAdvanceAllergyWorkflow3(
        _ input: Acme_Patients_V1_AdvanceAllergyWorkflowRequest
    ) -> Self {
        Acme_Patients_V1_SimulateAllergyRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.allergy.subject.displayName
                    $0.email = input.allergy.subject.email
                }
            }
            $0.context = input.context
        }
    }
}
