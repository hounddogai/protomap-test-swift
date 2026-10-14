import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Careplans_V1_CheckCareGoalEligibilityRequest {
    static func forPrescriptionCalculationEndpointGetPrescriptionRates0(
        _ input: Acme_Prescriptions_V1_GetPrescriptionRatesRequest
    ) -> Self {
        Acme_Careplans_V1_CheckCareGoalEligibilityRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_CheckCareGoalEligibilityRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
                $0.locale = input.context.locale
            }
        }
    }
}
