import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Careplans_V1_SimulateCarePlanRequest {
    static func forVitalCalculationEndpointQuoteVital1(
        _ input: Acme_Careplans_V1_QuoteVitalRequest
    ) -> Self {
        Acme_Careplans_V1_SimulateCarePlanRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_SimulateCarePlanRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.recipient = input.details.destination.recipient
                }
            }
        }
    }
}
