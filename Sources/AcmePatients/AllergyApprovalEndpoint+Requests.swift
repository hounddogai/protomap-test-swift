import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Patients_V1_GenerateMedicalRecordReportRequest {
    static func forAllergyApprovalEndpointEscalateAllergy1(
        _ input: Acme_Patients_V1_EscalateAllergyRequest
    ) -> Self {
        Acme_Patients_V1_GenerateMedicalRecordReportRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.reason = input.reason
        }
    }
}
