@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultStatementLedgerTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newDefaultStatementLedger("code-262", title: "title-178")
        #expect(item.status == RevenueCycle.DefaultStatementLedgerStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = RevenueCycle.newDefaultStatementLedger("code-262", title: "title-178")
        try item.moveTo(RevenueCycle.DefaultStatementLedgerStatus.retired)
        #expect(item.status == RevenueCycle.DefaultStatementLedgerStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newDefaultStatementLedger("code-262", title: "title-178")
        item.status = RevenueCycle.DefaultStatementLedgerStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DefaultStatementLedgerStatus.created) }
    }
}
