import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Careplans_V1_NormalizeCareGoalRequest {
    static func forClinicSlotCalculationEndpointSimulateClinicSlot3(
        _ input: Acme_Appointments_V1_SimulateClinicSlotRequest,
        reply0: Acme_Telehealth_V1_ValidateVisitNoteResponse,
        reply1: Acme_Appointments_V1_CheckAppointmentEligibilityResponse
    ) -> Self {
        Acme_Careplans_V1_NormalizeCareGoalRequest.with {
            $0.careGoal = Acme_Careplans_V1_CareGoal.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.email = reply0.visitNote.counterparty.email
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.clinicSlot.audit.createdAt
                    $0.updatedAt = input.clinicSlot.audit.updatedAt
                    $0.updatedBy = reply1.appointment.audit.updatedBy
                }
            }
            $0.context = input.context
        }
    }
}
