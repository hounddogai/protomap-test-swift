import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Identity_V1_ExplainUserDecisionRequest {
    static func forCarePlanCalculationEndpointEstimateCarePlan2(
        _ input: Acme_Careplans_V1_EstimateCarePlanRequest,
        reply0: Acme_Identity_V1_GetUserRulesResponse,
        reply1: Acme_Boxoffice_V1_QuoteBoxOfficeSaleResponse
    ) -> Self {
        Acme_Identity_V1_ExplainUserDecisionRequest.with {
            $0.context = input.context
            $0.user = Acme_Identity_V1_User.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.user.relationshipManager.email
                }
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.lines = input.details.destination.lines
                    $0.region = reply1.boxOfficeSale.billingAddress.region
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply0.user.relationshipManager.displayName
                }
            }
        }
    }
}
