import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Notifications_V1_ExplainNotificationDecisionRequest {
    static func forVideoVisitValidationEndpointPreviewVideoVisit1(
        _ input: Acme_Telehealth_V1_PreviewVideoVisitRequest,
        reply0: Acme_Careplans_V1_ScoreCareGoalResponse
    ) -> Self {
        Acme_Notifications_V1_ExplainNotificationDecisionRequest.with {
            $0.context = input.context
            $0.details = Acme_Notifications_V1_ExplainNotificationDecisionRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.careGoal.requester.email
                    $0.name = reply0.careGoal.requester.name
                }
            }
            $0.notification = Acme_Notifications_V1_Notification.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.careGoal.audit.createdBy
                }
                $0.customer = Acme_Notifications_V1_NotificationTemplateRef.with {
                    $0.displayName = input.videoVisit.organizer.displayName
                }
            }
        }
    }
}
