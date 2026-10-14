@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsScheduledRoundingScoreTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newScheduledRoundingScore("code-942", name: "name-886")
        #expect(item.status == ClinicalOps.ScheduledRoundingScoreStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = ClinicalOps.newScheduledRoundingScore("code-942", name: "name-886")
        try item.moveTo(ClinicalOps.ScheduledRoundingScoreStatus.running)
        #expect(item.status == ClinicalOps.ScheduledRoundingScoreStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newScheduledRoundingScore("code-942", name: "name-886")
        item.status = ClinicalOps.ScheduledRoundingScoreStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.ScheduledRoundingScoreStatus.new) }
    }
}
