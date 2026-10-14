import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Venues_V1_ValidateVenueRequest {
    static func forPatientWorkflowEndpointCancelPatientWorkflow1(
        _ input: Acme_Patients_V1_CancelPatientWorkflowRequest,
        reply0: Acme_Prescriptions_V1_CommentPrescriptionApprovalResponse
    ) -> Self {
        Acme_Venues_V1_ValidateVenueRequest.with {
            $0.context = input.context
            $0.details = Acme_Venues_V1_ValidateVenueRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.phone = input.details.notify.phone
                }
            }
            $0.venue = Acme_Venues_V1_Venue.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.locality = reply0.prescription.billingAddress.locality
                }
            }
        }
    }
}
