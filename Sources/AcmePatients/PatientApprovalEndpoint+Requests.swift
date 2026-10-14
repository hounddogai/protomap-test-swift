import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Patients_V1_CompareAllergyOptionsRequest {
    static func forPatientApprovalEndpointRejectPatient0(
        _ input: Acme_Patients_V1_RejectPatientRequest
    ) -> Self {
        Acme_Patients_V1_CompareAllergyOptionsRequest.with {
            $0.allergy = Acme_Patients_V1_Allergy.with {
                $0.subject = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.patient.relationshipManager.email
                }
            }
            $0.context = input.context
        }
    }
}
