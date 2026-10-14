import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Patients_V1_ExplainMedicalRecordCalculationRequest {
    static func forRefillLifecycleEndpointActivateRefill0(
        _ input: Acme_Prescriptions_V1_ActivateRefillRequest
    ) -> Self {
        Acme_Patients_V1_ExplainMedicalRecordCalculationRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_ExplainMedicalRecordCalculationRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.newOwner.email
                    $0.preferredChannel = input.details.notifyContact.preferredChannel
                }
            }
        }
    }
}
