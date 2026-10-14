import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Identity_V1_ResolveUsersRequest {
    static func forPatientHomeWorkflowEndpointListPatientHomeWorkflows0(
        _ input: Acme_Patientapp_V1_ListPatientHomeWorkflowsRequest
    ) -> Self {
        Acme_Identity_V1_ResolveUsersRequest.with {
            $0.context = input.context
        }
    }
}
