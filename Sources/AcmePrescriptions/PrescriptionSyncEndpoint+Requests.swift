import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Prescriptions_V1_ExplainMedicationCalculationRequest {
    static func forPrescriptionSyncEndpointPushPrescription2(
        _ input: Acme_Prescriptions_V1_PushPrescriptionRequest,
        reply0: Acme_Prescriptions_V1_EstimatePrescriptionResponse,
        reply1: Acme_Patients_V1_QuotePatientResponse
    ) -> Self {
        Acme_Prescriptions_V1_ExplainMedicationCalculationRequest.with {
            $0.context = input.context
            $0.medication = Acme_Prescriptions_V1_Medication.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.locality = reply0.prescription.billingAddress.locality
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.prescription.audit.createdAt
                    $0.updatedAt = reply1.patient.audit.updatedAt
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.prescription.counterparty.email
                }
            }
        }
    }
}
