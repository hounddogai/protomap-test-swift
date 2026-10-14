import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Notifications_V1_ResolveNotificationsRequest {
    static func forProviderWorkflowEndpointResumeProviderWorkflow2(
        _ input: Acme_Appointments_V1_ResumeProviderWorkflowRequest
    ) -> Self {
        Acme_Notifications_V1_ResolveNotificationsRequest.with {
            $0.context = input.context
        }
    }
}
