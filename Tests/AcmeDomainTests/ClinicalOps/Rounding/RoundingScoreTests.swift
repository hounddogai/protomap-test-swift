@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingScoreTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newRoundingScore("code-260", label: "label-723")
        #expect(item.status == ClinicalOps.RoundingScoreStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = ClinicalOps.newRoundingScore("code-260", label: "label-723")
        try item.moveTo(ClinicalOps.RoundingScoreStatus.approved)
        #expect(item.status == ClinicalOps.RoundingScoreStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newRoundingScore("code-260", label: "label-723")
        item.status = ClinicalOps.RoundingScoreStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RoundingScoreStatus.proposed) }
    }
}
