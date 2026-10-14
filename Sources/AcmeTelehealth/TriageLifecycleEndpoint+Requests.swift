import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Telehealth_V1_RecalculateVideoVisitsRequest {
    static func forTriageLifecycleEndpointGetTriageLifecycle0(
        _ input: Acme_Telehealth_V1_GetTriageLifecycleRequest
    ) -> Self {
        Acme_Telehealth_V1_RecalculateVideoVisitsRequest.with {
            $0.context = input.context
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                    $0.userID = input.context.actor.userID
                }
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.participantID = input.triageID
                    }
                ]
            }
        }
    }
}
