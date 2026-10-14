import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Telehealth_V1_PreviewVideoVisitRequest {
    static func forVideoVisitEndpointDeleteVideoVisit3(
        _ input: Acme_Telehealth_V1_DeleteVideoVisitRequest,
        reply0: Acme_Telehealth_V1_ValidateTriageResponse,
        reply2: Acme_Telehealth_V1_RecalculateVideoVisitsResponse
    ) -> Self {
        Acme_Telehealth_V1_PreviewVideoVisitRequest.with {
            $0.context = input.context
            $0.videoVisit = Acme_Telehealth_V1_VideoVisit.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.triage.audit.createdBy
                }
                $0.location = Acme_Common_V1_PostalAddress.with {
                    $0.region = reply2.videoVisit.location.region
                }
                $0.organizer = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply2.videoVisit.organizer.displayName
                }
                $0.participants = [
                    Acme_Telehealth_V1_VideoVisitParticipant.with {
                        $0.contact = Acme_Common_V1_ContactInfo.with {
                            $0.email = reply0.triage.assignee.email
                        }
                    }
                ]
            }
        }
    }
}
