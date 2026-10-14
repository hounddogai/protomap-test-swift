@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsSeasonalTaskEstimateTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newSeasonalTaskEstimate("code-212", label: "label-922")
        #expect(item.status == ClinicalOps.SeasonalTaskEstimateStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = ClinicalOps.newSeasonalTaskEstimate("code-212", label: "label-922")
        try item.moveTo(ClinicalOps.SeasonalTaskEstimateStatus.validated)
        #expect(item.status == ClinicalOps.SeasonalTaskEstimateStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newSeasonalTaskEstimate("code-212", label: "label-922")
        item.status = ClinicalOps.SeasonalTaskEstimateStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.SeasonalTaskEstimateStatus.created) }
    }
}
