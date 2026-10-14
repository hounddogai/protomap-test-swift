import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Telehealth_V1_ScoreVideoVisitRequest {
    static func forProviderValidationEndpointLintProviders0(
        _ input: Acme_Appointments_V1_LintProvidersRequest
    ) -> Self {
        Acme_Telehealth_V1_ScoreVideoVisitRequest.with {
            $0.context = input.context
            $0.details = Acme_Telehealth_V1_ScoreVideoVisitRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.countryCode = input.provider.primaryAddress.countryCode
                }
            }
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = input.provider.relationshipManager.email
                            $0.preferredChannel = input.provider.contact.preferredChannel
                        }
                    }
                ]
            }
        }
    }
}
