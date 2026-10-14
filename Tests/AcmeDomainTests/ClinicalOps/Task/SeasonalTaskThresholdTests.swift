@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsSeasonalTaskThresholdTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newSeasonalTaskThreshold("code-38", name: "name-331")
        #expect(item.status == ClinicalOps.SeasonalTaskThresholdStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = ClinicalOps.newSeasonalTaskThreshold("code-38", name: "name-331")
        try item.moveTo(ClinicalOps.SeasonalTaskThresholdStatus.closed)
        #expect(item.status == ClinicalOps.SeasonalTaskThresholdStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newSeasonalTaskThreshold("code-38", name: "name-331")
        item.status = ClinicalOps.SeasonalTaskThresholdStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.SeasonalTaskThresholdStatus.draft) }
    }
}
