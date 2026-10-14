import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Patientapp_V1_SummarizeCareInboxesRequest {
    static func forPatientHomeEndpointClonePatientHome0(
        _ input: Acme_Patientapp_V1_ClonePatientHomeRequest
    ) -> Self {
        Acme_Patientapp_V1_SummarizeCareInboxesRequest.with {
            $0.annotations = input.context.baggage
            $0.context = input.context
            $0.details = Acme_Patientapp_V1_SummarizeCareInboxesRequest.Details.with {
                $0.filters = input.patientHome.customFields
            }
        }
    }
}
