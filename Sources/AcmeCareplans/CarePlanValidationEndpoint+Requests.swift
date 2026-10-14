import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Broadcasts_V1_CountBroadcastsRequest {
    static func forCarePlanValidationEndpointExplainCarePlanDecision1(
        _ input: Acme_Careplans_V1_ExplainCarePlanDecisionRequest
    ) -> Self {
        Acme_Broadcasts_V1_CountBroadcastsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Broadcasts_V1_CountBroadcastsRequest.Filter.with {
                $0.region = input.carePlan.billingAddress.region
            }
        }
    }
}
