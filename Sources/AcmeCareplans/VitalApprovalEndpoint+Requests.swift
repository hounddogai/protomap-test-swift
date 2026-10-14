import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Prescriptions_V1_FindPrescriptionsRequest {
    static func forVitalApprovalEndpointGetVitalApprovalStatus0(
        _ input: Acme_Careplans_V1_GetVitalApprovalStatusRequest
    ) -> Self {
        Acme_Prescriptions_V1_FindPrescriptionsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Prescriptions_V1_FindPrescriptionsRequest.Filter.with {
                $0.ownerID = input.vitalID
            }
        }
    }
}
