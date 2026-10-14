import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Prescriptions_V1_NormalizeMedicationRequest {
    static func forPrescriptionQueryEndpointSummarizePrescriptions3(
        _ input: Acme_Prescriptions_V1_SummarizePrescriptionsRequest,
        reply0: Acme_Prescriptions_V1_CheckMedicationEligibilityResponse,
        reply1: Acme_Prescriptions_V1_ScorePrescriptionResponse
    ) -> Self {
        Acme_Prescriptions_V1_NormalizeMedicationRequest.with {
            $0.context = input.context
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = reply1.prescription.billingAddress.postalCode
                    $0.region = reply1.prescription.billingAddress.region
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply1.prescription.audit.etag
                }
                $0.dimensions = Acme_Prescriptions_V1_MedicationDimensions.with {
                    $0.unit = reply0.medication.dimensions.unit
                }
            }
        }
    }
}
