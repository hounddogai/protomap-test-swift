import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Appointments_V1_ExplainProviderDecisionRequest {
    static func forClinicSlotValidationEndpointValidateClinicSlot1(
        _ input: Acme_Appointments_V1_ValidateClinicSlotRequest,
        reply0: Acme_Careplans_V1_SimulateCareGoalResponse
    ) -> Self {
        Acme_Appointments_V1_ExplainProviderDecisionRequest.with {
            $0.context = input.context
            $0.details = Acme_Appointments_V1_ExplainProviderDecisionRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.phone = reply0.careGoal.requester.phone
                    $0.preferredChannel = reply0.careGoal.requester.preferredChannel
                }
            }
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.careGoal.assignee.email
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.userID = reply0.careGoal.assignee.userID
                }
            }
        }
    }
}
