import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Patients_V1_RetryAllergyWorkflowRequest {
    static func forPatientHomeGatewayEndpointComposePatientHomePage2(
        _ input: Acme_Patientapp_V1_ComposePatientHomePageRequest,
        reply1: Acme_Patientapp_V1_RetryPatientHomeWorkflowResponse
    ) -> Self {
        Acme_Patients_V1_RetryAllergyWorkflowRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_RetryAllergyWorkflowRequest.Details.with {
                $0.notify = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply1.patientHome.assignee.email
                }
            }
        }
    }
}
