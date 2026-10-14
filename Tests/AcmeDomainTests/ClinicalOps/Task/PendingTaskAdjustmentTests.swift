@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingTaskAdjustmentTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newPendingTaskAdjustment("code-525", title: "title-339")
        #expect(item.status == ClinicalOps.PendingTaskAdjustmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = ClinicalOps.newPendingTaskAdjustment("code-525", title: "title-339")
        try item.moveTo(ClinicalOps.PendingTaskAdjustmentStatus.closed)
        #expect(item.status == ClinicalOps.PendingTaskAdjustmentStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newPendingTaskAdjustment("code-525", title: "title-339")
        item.status = ClinicalOps.PendingTaskAdjustmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.PendingTaskAdjustmentStatus.draft) }
    }
}
