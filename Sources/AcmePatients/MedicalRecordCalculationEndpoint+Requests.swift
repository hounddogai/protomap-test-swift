import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Patients_V1_RecalculatePatientsRequest {
    static func forMedicalRecordCalculationEndpointCompareMedicalRecordOptions0(
        _ input: Acme_Patients_V1_CompareMedicalRecordOptionsRequest
    ) -> Self {
        Acme_Patients_V1_RecalculatePatientsRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_RecalculatePatientsRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.medicalRecord.billingAddress.region
                }
            }
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.medicalRecord.billingAddress.countryCode
                    $0.recipient = input.details.destination.recipient
                }
            }
        }
    }
}
