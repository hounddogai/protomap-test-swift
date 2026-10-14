import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Patients_V1_ExplainMedicalRecordCalculationRequest {
    static func forAllergyCalculationEndpointGetAllergyRates1(
        _ input: Acme_Patients_V1_GetAllergyRatesRequest,
        reply0: Acme_Prescriptions_V1_LintMedicationsResponse
    ) -> Self {
        Acme_Patients_V1_ExplainMedicalRecordCalculationRequest.with {
            $0.context = input.context
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply0.medication.audit.etag
                }
            }
        }
    }
}
