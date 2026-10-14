import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Metrics_V1_CloneMetricSeriesRequest {
    static func forTriageCalculationEndpointEstimateTriage0(
        _ input: Acme_Telehealth_V1_EstimateTriageRequest
    ) -> Self {
        Acme_Metrics_V1_CloneMetricSeriesRequest.with {
            $0.context = input.context
            $0.metricSeries = Acme_Metrics_V1_MetricSeries.with {
                $0.address = Acme_Common_V1_PostalAddress.with {
                    $0.postalCode = input.details.destination.postalCode
                    $0.recipient = input.details.destination.recipient
                }
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.triage.assignee.displayName
                }
            }
        }
    }
}
