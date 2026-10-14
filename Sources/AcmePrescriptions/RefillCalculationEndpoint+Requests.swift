import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Prescriptions_V1_CalculatePrescriptionRequest {
    static func forRefillCalculationEndpointCompareRefillOptions1(
        _ input: Acme_Prescriptions_V1_CompareRefillOptionsRequest
    ) -> Self {
        Acme_Prescriptions_V1_CalculatePrescriptionRequest.with {
            $0.context = input.context
            $0.details = Acme_Prescriptions_V1_CalculatePrescriptionRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.details.destination.countryCode
                    $0.region = input.details.destination.region
                }
            }
            $0.prescription = Acme_Prescriptions_V1_Prescription.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = input.refill.audit.createdBy
                }
            }
        }
    }
}
