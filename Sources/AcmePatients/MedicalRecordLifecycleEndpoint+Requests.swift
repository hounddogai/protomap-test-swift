import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Prescriptions_V1_ListMedicationReportsRequest {
    static func forMedicalRecordLifecycleEndpointReinstateMedicalRecord1(
        _ input: Acme_Patients_V1_ReinstateMedicalRecordRequest
    ) -> Self {
        Acme_Prescriptions_V1_ListMedicationReportsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Prescriptions_V1_ListMedicationReportsRequest.Filter.with {
                $0.createdAfter = input.details.effectiveAt
                $0.ownerID = input.details.newOwner.userID
            }
        }
    }
}
