import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Prescriptions_V1_SuggestMedicationsRequest {
    static func forPrescriptionWorkflowEndpointAdvancePrescriptionWorkflow1(
        _ input: Acme_Prescriptions_V1_AdvancePrescriptionWorkflowRequest,
        reply0: Acme_Prescriptions_V1_ResolveMedicationConflictResponse
    ) -> Self {
        Acme_Prescriptions_V1_SuggestMedicationsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Prescriptions_V1_SuggestMedicationsRequest.Filter.with {
                $0.createdAfter = input.prescription.audit.createdAt
                $0.labels = input.prescription.metadata
                $0.ownerID = reply0.medication.components["primary", default: .init()].componentID
                $0.region = input.prescription.billingAddress.region
            }
        }
    }
}
