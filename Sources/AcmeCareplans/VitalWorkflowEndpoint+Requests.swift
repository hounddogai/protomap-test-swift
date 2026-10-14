import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Careplans_V1_StartCarePlanWorkflowRequest {
    static func forVitalWorkflowEndpointCancelVitalWorkflow0(
        _ input: Acme_Careplans_V1_CancelVitalWorkflowRequest
    ) -> Self {
        Acme_Careplans_V1_StartCarePlanWorkflowRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.appointmentID = input.vital.subject.appointmentID
                    $0.displayName = input.vital.subject.displayName
                }
            }
            $0.context = input.context
            $0.details = Acme_Careplans_V1_StartCarePlanWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = input.details.notify.preferredChannel
                }
            }
        }
    }
}
