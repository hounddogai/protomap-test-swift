import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Venues_V1_PreviewVenueRequest {
    static func forCareInboxIntegrationEndpointDisconnectCareInboxSource1(
        _ input: Acme_Patientapp_V1_DisconnectCareInboxSourceRequest,
        reply0: Acme_Patients_V1_EstimateAllergyResponse
    ) -> Self {
        Acme_Venues_V1_PreviewVenueRequest.with {
            $0.context = input.context
            $0.venue = Acme_Venues_V1_Venue.with {
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply0.allergy.subject.displayName
                }
            }
        }
    }
}
