import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Careplans_V1_EstimateCareGoalRequest {
    static func forVitalValidationEndpointCheckVitalEligibility1(
        _ input: Acme_Careplans_V1_CheckVitalEligibilityRequest,
        reply0: Acme_Careplans_V1_RecalculateCarePlansResponse
    ) -> Self {
        Acme_Careplans_V1_EstimateCareGoalRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply0.carePlan.counterparty.displayName
                    $0.email = input.details.contact.email
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = reply0.carePlan.audit.createdAt
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = input.details.contact.preferredChannel
                }
            }
            $0.context = input.context
        }
    }
}
