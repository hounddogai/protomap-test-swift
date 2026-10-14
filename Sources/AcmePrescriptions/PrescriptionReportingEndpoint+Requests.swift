import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Careplans_V1_ExplainCarePlanCalculationRequest {
    static func forPrescriptionReportingEndpointStreamPrescriptionMetrics1(
        _ input: Acme_Prescriptions_V1_StreamPrescriptionMetricsRequest,
        reply0: Acme_Prescriptions_V1_ValidateRefillImportResponse
    ) -> Self {
        Acme_Careplans_V1_ExplainCarePlanCalculationRequest.with {
            $0.carePlan = Acme_Careplans_V1_CarePlan.with {
                $0.counterparty = Acme_Appointments_V1_AppointmentRef.with {
                    $0.displayName = reply0.refill.assignee.displayName
                }
            }
            $0.context = input.context
        }
    }
}
