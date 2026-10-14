import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Telehealth_V1_CommentVisitNoteApprovalRequest {
    static func forAppointmentWorkflowEndpointAdvanceAppointmentWorkflow1(
        _ input: Acme_Appointments_V1_AdvanceAppointmentWorkflowRequest,
        reply0: Acme_Prescriptions_V1_PushRefillResponse
    ) -> Self {
        Acme_Telehealth_V1_CommentVisitNoteApprovalRequest.with {
            $0.context = input.context
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.refill.audit.createdBy
                    $0.etag = reply0.refill.audit.etag
                }
                $0.counterparty = Acme_Patients_V1_PatientRef.with {
                    $0.displayName = input.appointment.organizer.displayName
                }
            }
        }
    }
}
