@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingAlertTierTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newPendingAlertTier("code-395", name: "name-311")
        #expect(item.status == ClinicalOps.PendingAlertTierStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = ClinicalOps.newPendingAlertTier("code-395", name: "name-311")
        try item.moveTo(ClinicalOps.PendingAlertTierStatus.pending)
        #expect(item.status == ClinicalOps.PendingAlertTierStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newPendingAlertTier("code-395", name: "name-311")
        item.status = ClinicalOps.PendingAlertTierStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.PendingAlertTierStatus.draft) }
    }
}
