import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Appointments_V1_NormalizeClinicSlotRequest {
    static func forProviderApprovalEndpointRecallProvider0(
        _ input: Acme_Appointments_V1_RecallProviderRequest
    ) -> Self {
        Acme_Appointments_V1_NormalizeClinicSlotRequest.with {
            $0.clinicSlot = Acme_Appointments_V1_ClinicSlot.with {
                $0.participants = [
                    Acme_Appointments_V1_ClinicSlotParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.name = input.provider.contact.name
                            $0.phone = input.provider.contact.phone
                            $0.preferredChannel = input.provider.contact.preferredChannel
                        }
                    }
                ]
            }
            $0.context = input.context
        }
    }
}
