import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Careplans_V1_ScoreCarePlanRequest {
    static func forCarePlanLifecycleEndpointReinstateCarePlan1(
        _ input: Acme_Careplans_V1_ReinstateCarePlanRequest,
        reply0: Acme_Careplans_V1_SimulateCareGoalResponse
    ) -> Self {
        Acme_Careplans_V1_ScoreCarePlanRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.careGoal.audit.createdBy
                    $0.updatedBy = reply0.careGoal.audit.updatedBy
                }
                $0.dueAt = reply0.careGoal.sla.dueAt
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_ScoreCarePlanRequest.Details.with {
                $0.currencyCode = reply0.breakdown.currencyCode
            }
        }
    }
}
