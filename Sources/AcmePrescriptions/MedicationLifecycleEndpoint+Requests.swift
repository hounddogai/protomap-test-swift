import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Careplans_V1_ListPendingVitalsRequest {
    static func forMedicationLifecycleEndpointRenewMedication2(
        _ input: Acme_Prescriptions_V1_RenewMedicationRequest
    ) -> Self {
        Acme_Careplans_V1_ListPendingVitalsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Careplans_V1_ListPendingVitalsRequest.Filter.with {
                $0.createdAfter = input.details.effectiveAt
            }
        }
    }
}
