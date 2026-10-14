@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsSeasonalRoundingAuditTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newSeasonalRoundingAudit("code-171", name: "name-769")
        #expect(item.status == ClinicalOps.SeasonalRoundingAuditStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = ClinicalOps.newSeasonalRoundingAudit("code-171", name: "name-769")
        try item.moveTo(ClinicalOps.SeasonalRoundingAuditStatus.pending)
        #expect(item.status == ClinicalOps.SeasonalRoundingAuditStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newSeasonalRoundingAudit("code-171", name: "name-769")
        item.status = ClinicalOps.SeasonalRoundingAuditStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.SeasonalRoundingAuditStatus.draft) }
    }
}
