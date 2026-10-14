import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Telehealth_V1_QuoteVisitNoteRequest {
    static func forCarePlanApprovalEndpointCommentCarePlanApproval3(
        _ input: Acme_Careplans_V1_CommentCarePlanApprovalRequest,
        reply1: Acme_Prescriptions_V1_ScorePrescriptionResponse,
        reply2: Acme_Careplans_V1_RecalculateCareGoalsResponse
    ) -> Self {
        Acme_Telehealth_V1_QuoteVisitNoteRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_QuoteVisitNoteRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.carePlan.billingAddress.countryCode
                }
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = reply2.careGoal.audit.etag
                }
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = reply1.prescription.billingAddress.region
                }
            }
        }
    }
}
