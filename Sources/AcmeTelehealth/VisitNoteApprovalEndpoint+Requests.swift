import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Telehealth_V1_CompareVisitNoteOptionsRequest {
    static func forVisitNoteApprovalEndpointApproveVisitNote0(
        _ input: Acme_Telehealth_V1_ApproveVisitNoteRequest
    ) -> Self {
        Acme_Telehealth_V1_CompareVisitNoteOptionsRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_CompareVisitNoteOptionsRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.locality = input.visitNote.billingAddress.locality
                }
            }
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.email = input.visitNote.counterparty.email
                }
            }
        }
    }
}
