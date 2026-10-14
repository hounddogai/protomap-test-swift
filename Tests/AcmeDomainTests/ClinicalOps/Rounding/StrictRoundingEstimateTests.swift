@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictRoundingEstimateTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newStrictRoundingEstimate("code-603", name: "name-965")
        #expect(item.status == ClinicalOps.StrictRoundingEstimateStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = ClinicalOps.newStrictRoundingEstimate("code-603", name: "name-965")
        try item.moveTo(ClinicalOps.StrictRoundingEstimateStatus.queued)
        #expect(item.status == ClinicalOps.StrictRoundingEstimateStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newStrictRoundingEstimate("code-603", name: "name-965")
        item.status = ClinicalOps.StrictRoundingEstimateStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.StrictRoundingEstimateStatus.new) }
    }
}
