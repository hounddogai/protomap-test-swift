import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Patients_V1_FindPatientsRequest {
    static func forPatientEndpointSearchPatients1(
        _ input: Acme_Patients_V1_SearchPatientsRequest
    ) -> Self {
        Acme_Patients_V1_FindPatientsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patients_V1_FindPatientsRequest.Filter.with {
                $0.query = input.filter.query
                $0.region = input.filter.region
                $0.statuses = input.filter.statuses
            }
            $0.page = Acme_Common_V1_PageRequest.with {
                $0.pageToken = input.page.pageToken
            }
        }
    }
}
