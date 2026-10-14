import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Featureflags_V1_CountFeatureFlagsRequest {
    static func forMedicationQueryEndpointSummarizeMedications2(
        _ input: Acme_Prescriptions_V1_SummarizeMedicationsRequest,
        reply0: Acme_Seating_V1_CloneSeatMapResponse,
        reply1: Acme_Metrics_V1_UpdateMetricSeriesResponse
    ) -> Self {
        Acme_Featureflags_V1_CountFeatureFlagsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Featureflags_V1_CountFeatureFlagsRequest.Filter.with {
                $0.createdAfter = reply1.metricSeries.audit.updatedAt
                $0.region = reply0.seatMap.location.region
            }
        }
    }
}
