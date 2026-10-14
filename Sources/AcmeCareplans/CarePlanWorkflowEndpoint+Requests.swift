import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Careplans_V1_FindCarePlansRequest {
    static func forCarePlanWorkflowEndpointCancelCarePlanWorkflow0(
        _ input: Acme_Careplans_V1_CancelCarePlanWorkflowRequest
    ) -> Self {
        Acme_Careplans_V1_FindCarePlansRequest.with {
            $0.context = input.context
            $0.filter = Acme_Careplans_V1_FindCarePlansRequest.Filter.with {
                $0.createdAfter = input.carePlan.audit.createdAt
                $0.region = input.carePlan.billingAddress.region
            }
        }
    }
}
