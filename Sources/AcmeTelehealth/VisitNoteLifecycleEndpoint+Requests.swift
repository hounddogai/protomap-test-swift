import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Telehealth_V1_CompareVisitNoteOptionsRequest {
    static func forVisitNoteLifecycleEndpointScheduleVisitNoteExpiry3(
        _ input: Acme_Telehealth_V1_ScheduleVisitNoteExpiryRequest,
        reply0: Acme_Telehealth_V1_EstimateTriageResponse
    ) -> Self {
        Acme_Telehealth_V1_CompareVisitNoteOptionsRequest.with {
            $0.context = input.context
            $0.visitNote = Acme_Telehealth_V1_VisitNote.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.triage.audit.createdBy
                    $0.updatedAt = reply0.triage.audit.updatedAt
                }
            }
        }
    }
}
