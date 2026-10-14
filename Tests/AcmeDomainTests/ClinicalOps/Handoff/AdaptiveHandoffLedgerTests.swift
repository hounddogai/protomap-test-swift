@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAdaptiveHandoffLedgerTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newAdaptiveHandoffLedger("code-962", title: "title-497")
        #expect(item.status == ClinicalOps.AdaptiveHandoffLedgerStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = ClinicalOps.newAdaptiveHandoffLedger("code-962", title: "title-497")
        try item.moveTo(ClinicalOps.AdaptiveHandoffLedgerStatus.approved)
        #expect(item.status == ClinicalOps.AdaptiveHandoffLedgerStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newAdaptiveHandoffLedger("code-962", title: "title-497")
        item.status = ClinicalOps.AdaptiveHandoffLedgerStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AdaptiveHandoffLedgerStatus.proposed) }
    }
}
