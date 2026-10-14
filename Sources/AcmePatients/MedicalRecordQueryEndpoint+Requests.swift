import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Patients_V1_FindPatientsRequest {
    static func forMedicalRecordQueryEndpointSuggestMedicalRecords1(
        _ input: Acme_Patients_V1_SuggestMedicalRecordsRequest,
        reply0: Acme_Appointments_V1_ScoreAppointmentResponse
    ) -> Self {
        Acme_Patients_V1_FindPatientsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Patients_V1_FindPatientsRequest.Filter.with {
                $0.ownerID = input.filter.ownerID
                $0.region = reply0.appointment.location.region
            }
            $0.page = Acme_Common_V1_PageRequest.with {
                $0.pageSize = input.page.pageSize
                $0.pageToken = input.page.pageToken
            }
        }
    }
}
