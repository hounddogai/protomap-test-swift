import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Authorization_V1_ResolveAccessPoliciesRequest {
    static func forRefillApprovalEndpointDelegateRefillApproval0(
        _ input: Acme_Prescriptions_V1_DelegateRefillApprovalRequest
    ) -> Self {
        Acme_Authorization_V1_ResolveAccessPoliciesRequest.with {
            $0.context = input.context
        }
    }
}
