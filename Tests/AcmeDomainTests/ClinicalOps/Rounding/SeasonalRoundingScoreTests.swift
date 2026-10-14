@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsSeasonalRoundingScoreTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newSeasonalRoundingScore("code-732", label: "label-821")
        #expect(item.status == ClinicalOps.SeasonalRoundingScoreStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = ClinicalOps.newSeasonalRoundingScore("code-732", label: "label-821")
        try item.moveTo(ClinicalOps.SeasonalRoundingScoreStatus.withdrawn)
        #expect(item.status == ClinicalOps.SeasonalRoundingScoreStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newSeasonalRoundingScore("code-732", label: "label-821")
        item.status = ClinicalOps.SeasonalRoundingScoreStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.SeasonalRoundingScoreStatus.proposed) }
    }
}
