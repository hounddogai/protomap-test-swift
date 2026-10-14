@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetScoreTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newOrderSetScore("code-515", name: "name-456")
        #expect(item.status == ClinicalOps.OrderSetScoreStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = ClinicalOps.newOrderSetScore("code-515", name: "name-456")
        try item.moveTo(ClinicalOps.OrderSetScoreStatus.pending)
        #expect(item.status == ClinicalOps.OrderSetScoreStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newOrderSetScore("code-515", name: "name-456")
        item.status = ClinicalOps.OrderSetScoreStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetScoreStatus.draft) }
    }
}
