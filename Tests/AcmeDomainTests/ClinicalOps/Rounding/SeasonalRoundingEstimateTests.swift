@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsSeasonalRoundingEstimateTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newSeasonalRoundingEstimate("code-739", name: "name-967")
        #expect(item.status == ClinicalOps.SeasonalRoundingEstimateStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = ClinicalOps.newSeasonalRoundingEstimate("code-739", name: "name-967")
        try item.moveTo(ClinicalOps.SeasonalRoundingEstimateStatus.revoked)
        #expect(item.status == ClinicalOps.SeasonalRoundingEstimateStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newSeasonalRoundingEstimate("code-739", name: "name-967")
        item.status = ClinicalOps.SeasonalRoundingEstimateStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.SeasonalRoundingEstimateStatus.requested) }
    }
}
