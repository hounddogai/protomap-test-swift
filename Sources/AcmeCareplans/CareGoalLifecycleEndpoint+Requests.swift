import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Telehealth_V1_ExplainVisitNoteCalculationRequest {
    static func forCareGoalLifecycleEndpointRenewCareGoal1(
        _ input: Acme_Careplans_V1_RenewCareGoalRequest
    ) -> Self {
        Acme_Telehealth_V1_ExplainVisitNoteCalculationRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_ExplainVisitNoteCalculationRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.name = input.details.notifyContact.name
                    $0.preferredChannel = input.details.notifyContact.preferredChannel
                }
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.details.notifyContact.email
                }
            }
        }
    }
}
