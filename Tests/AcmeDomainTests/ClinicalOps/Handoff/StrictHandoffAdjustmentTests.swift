@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictHandoffAdjustmentTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newStrictHandoffAdjustment("code-666", name: "name-158")
        #expect(item.status == ClinicalOps.StrictHandoffAdjustmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = ClinicalOps.newStrictHandoffAdjustment("code-666", name: "name-158")
        try item.moveTo(ClinicalOps.StrictHandoffAdjustmentStatus.pending)
        #expect(item.status == ClinicalOps.StrictHandoffAdjustmentStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newStrictHandoffAdjustment("code-666", name: "name-158")
        item.status = ClinicalOps.StrictHandoffAdjustmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.StrictHandoffAdjustmentStatus.draft) }
    }
}
