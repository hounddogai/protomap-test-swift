@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredRoundingScoreTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newTieredRoundingScore("code-364", name: "name-778")
        #expect(item.status == ClinicalOps.TieredRoundingScoreStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = ClinicalOps.newTieredRoundingScore("code-364", name: "name-778")
        try item.moveTo(ClinicalOps.TieredRoundingScoreStatus.reopened)
        #expect(item.status == ClinicalOps.TieredRoundingScoreStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newTieredRoundingScore("code-364", name: "name-778")
        item.status = ClinicalOps.TieredRoundingScoreStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TieredRoundingScoreStatus.`open`) }
    }
}
