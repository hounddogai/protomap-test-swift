import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Search_V1_BrowseSearchIndexesRequest {
    static func forVisitNoteCalculationEndpointExplainVisitNoteCalculation2(
        _ input: Acme_Telehealth_V1_ExplainVisitNoteCalculationRequest,
        reply0: Acme_Telehealth_V1_RecalculateVideoVisitsResponse
    ) -> Self {
        Acme_Search_V1_BrowseSearchIndexesRequest.with {
            $0.context = input.context
            $0.filter = Acme_Search_V1_BrowseSearchIndexesRequest.Filter.with {
                $0.createdAfter = reply0.videoVisit.audit.createdAt
                $0.region = reply0.videoVisit.location.region
            }
        }
    }
}
