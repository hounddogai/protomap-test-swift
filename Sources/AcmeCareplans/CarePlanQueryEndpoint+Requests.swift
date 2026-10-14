import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Venues_V1_NormalizeVenueRequest {
    static func forCarePlanQueryEndpointResolveCarePlans0(
        _ input: Acme_Careplans_V1_ResolveCarePlansRequest
    ) -> Self {
        Acme_Venues_V1_NormalizeVenueRequest.with {
            $0.context = input.context
            $0.venue = Acme_Venues_V1_Venue.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.email = input.context.actor.email
                    $0.userID = input.context.actor.userID
                }
            }
        }
    }
}
