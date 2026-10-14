import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Appointments_V1_ExplainProviderDecisionRequest {
    static func forClinicSlotApprovalEndpointListPendingClinicSlots0(
        _ input: Acme_Appointments_V1_ListPendingClinicSlotsRequest
    ) -> Self {
        Acme_Appointments_V1_ExplainProviderDecisionRequest.with {
            $0.context = input.context
            $0.provider = Acme_Appointments_V1_Provider.with {
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                    $0.userID = input.context.actor.userID
                }
            }
        }
    }
}
