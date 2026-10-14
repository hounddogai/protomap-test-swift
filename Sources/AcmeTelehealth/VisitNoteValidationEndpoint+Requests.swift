import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Telehealth_V1_CalculateTriageRequest {
    static func forVisitNoteValidationEndpointExplainVisitNoteDecision0(
        _ input: Acme_Telehealth_V1_ExplainVisitNoteDecisionRequest
    ) -> Self {
        Acme_Telehealth_V1_CalculateTriageRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_CalculateTriageRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.lines = input.visitNote.billingAddress.lines
                }
            }
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.visitNote.audit.etag
                }
                $0.requester = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.visitNote.counterparty.email
                    $0.name = input.details.contact.name
                }
            }
        }
    }
}
