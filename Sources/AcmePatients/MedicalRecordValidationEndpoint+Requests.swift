import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Patients_V1_QuotePatientRequest {
    static func forMedicalRecordValidationEndpointPreviewMedicalRecord1(
        _ input: Acme_Patients_V1_PreviewMedicalRecordRequest
    ) -> Self {
        Acme_Patients_V1_QuotePatientRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = input.medicalRecord.billingAddress.lines
                }
            }
        }
    }
}
