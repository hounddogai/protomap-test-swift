@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalCareProtocolEstimateTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newRegionalCareProtocolEstimate("code-458", label: "label-312")
        #expect(item.status == ClinicalOps.RegionalCareProtocolEstimateStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = ClinicalOps.newRegionalCareProtocolEstimate("code-458", label: "label-312")
        try item.moveTo(ClinicalOps.RegionalCareProtocolEstimateStatus.cancelled)
        #expect(item.status == ClinicalOps.RegionalCareProtocolEstimateStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newRegionalCareProtocolEstimate("code-458", label: "label-312")
        item.status = ClinicalOps.RegionalCareProtocolEstimateStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RegionalCareProtocolEstimateStatus.planned) }
    }
}
