import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Metrics_V1_SummarizeMetricSeriesesRequest {
    static func forRefillValidationEndpointLintRefills0(
        _ input: Acme_Prescriptions_V1_LintRefillsRequest
    ) -> Self {
        Acme_Metrics_V1_SummarizeMetricSeriesesRequest.with {
            $0.annotations = input.annotations
            $0.context = input.context
            $0.details = Acme_Metrics_V1_SummarizeMetricSeriesesRequest.Details.with {
                $0.filters = input.refill.customFields
            }
            $0.reason = input.reason
        }
    }
}
