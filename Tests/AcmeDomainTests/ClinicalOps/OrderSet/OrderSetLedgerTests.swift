@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetLedgerTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newOrderSetLedger("code-727", name: "name-95")
        #expect(item.status == ClinicalOps.OrderSetLedgerStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = ClinicalOps.newOrderSetLedger("code-727", name: "name-95")
        try item.moveTo(ClinicalOps.OrderSetLedgerStatus.revoked)
        #expect(item.status == ClinicalOps.OrderSetLedgerStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newOrderSetLedger("code-727", name: "name-95")
        item.status = ClinicalOps.OrderSetLedgerStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetLedgerStatus.requested) }
    }
}
