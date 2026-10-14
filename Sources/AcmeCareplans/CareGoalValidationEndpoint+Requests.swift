import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Careplans_V1_CalculateCareGoalRequest {
    static func forCareGoalValidationEndpointScoreCareGoal0(
        _ input: Acme_Careplans_V1_ScoreCareGoalRequest
    ) -> Self {
        Acme_Careplans_V1_CalculateCareGoalRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = input.careGoal.audit.createdBy
                }
            }
            $0.context = input.context
        }
    }
}
