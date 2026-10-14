import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Appointments_V1_AdvanceClinicSlotWorkflowRequest {
    static func forPatientHomeNotificationEndpointSubscribePatientHomeUpdates0(
        _ input: Acme_Patientapp_V1_SubscribePatientHomeUpdatesRequest
    ) -> Self {
        Acme_Appointments_V1_AdvanceClinicSlotWorkflowRequest.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.email = input.details.recipient.email
                }
                $0.participants = [
                    Acme_Appointments_V1_ClinicSlotParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.preferredChannel = input.details.recipient.preferredChannel
                        }
                    }
                ]
            }
            $0.context = input.context
        }
    }
}
