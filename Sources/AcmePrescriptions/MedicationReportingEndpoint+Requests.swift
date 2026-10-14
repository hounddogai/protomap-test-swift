import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Expenses_V1_ResolveExpenseReportsRequest {
    static func forMedicationReportingEndpointStreamMedicationMetrics1(
        _ input: Acme_Prescriptions_V1_StreamMedicationMetricsRequest
    ) -> Self {
        Acme_Expenses_V1_ResolveExpenseReportsRequest.with {
            $0.context = input.context
        }
    }
}
