@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementLedgerTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newStatementLedger("code-212", label: "label-416")
        #expect(item.status == RevenueCycle.StatementLedgerStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = RevenueCycle.newStatementLedger("code-212", label: "label-416")
        try item.moveTo(RevenueCycle.StatementLedgerStatus.expired)
        #expect(item.status == RevenueCycle.StatementLedgerStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newStatementLedger("code-212", label: "label-416")
        item.status = RevenueCycle.StatementLedgerStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StatementLedgerStatus.requested) }
    }
}
