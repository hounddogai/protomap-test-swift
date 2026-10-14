import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Metrics_V1_ExplainMetricSeriesDecisionRequest {
    static func forCareGoalCalculationEndpointCompareCareGoalOptions0(
        _ input: Acme_Careplans_V1_CompareCareGoalOptionsRequest
    ) -> Self {
        Acme_Metrics_V1_ExplainMetricSeriesDecisionRequest.with {
            $0.context = input.context
            $0.metricSeries = Acme_Metrics_V1_MetricSeries.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.region = input.details.destination.region
                }
            }
        }
    }
}
