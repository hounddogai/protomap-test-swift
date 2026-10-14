@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffAdjustmentTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newHandoffAdjustment("code-512", title: "title-556")
        #expect(item.status == ClinicalOps.HandoffAdjustmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = ClinicalOps.newHandoffAdjustment("code-512", title: "title-556")
        try item.moveTo(ClinicalOps.HandoffAdjustmentStatus.pending)
        #expect(item.status == ClinicalOps.HandoffAdjustmentStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newHandoffAdjustment("code-512", title: "title-556")
        item.status = ClinicalOps.HandoffAdjustmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.HandoffAdjustmentStatus.draft) }
    }
}
