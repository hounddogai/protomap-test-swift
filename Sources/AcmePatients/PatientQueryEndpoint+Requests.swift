import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Patients_V1_RecalculateAllergiesRequest {
    static func forPatientQueryEndpointFindPatients0(
        _ input: Acme_Patients_V1_FindPatientsRequest
    ) -> Self {
        Acme_Patients_V1_RecalculateAllergiesRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_RecalculateAllergiesRequest.Details.with {
                $0.destination = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.filter.region
                }
            }
        }
    }
}
