import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Appointments_V1_LintProvidersRequest {
    static func forAppointmentEndpointCreateAppointment1(
        _ input: Acme_Appointments_V1_CreateAppointmentRequest,
        reply0: Acme_Appointments_V1_ScoreClinicSlotResponse
    ) -> Self {
        Acme_Appointments_V1_LintProvidersRequest.with {
            $0.context = input.context
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = reply0.clinicSlot.audit.updatedAt
                }
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = reply0.clinicSlot.location.postalCode
                }
            }
        }
    }
}
