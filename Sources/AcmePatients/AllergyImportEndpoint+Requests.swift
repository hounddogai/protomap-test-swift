import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Careplans_V1_ListCareGoalWorkflowsRequest {
    static func forAllergyImportEndpointValidateAllergyImport0(
        _ input: Acme_Patients_V1_ValidateAllergyImportRequest
    ) -> Self {
        Acme_Careplans_V1_ListCareGoalWorkflowsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Careplans_V1_ListCareGoalWorkflowsRequest.Filter.with {
                $0.ownerID = input.allergy.subject.patientID
            }
        }
    }
}
