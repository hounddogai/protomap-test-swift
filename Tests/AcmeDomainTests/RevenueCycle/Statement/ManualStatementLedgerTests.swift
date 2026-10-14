@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualStatementLedgerTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newManualStatementLedger("code-1", name: "name-93")
        #expect(item.status == RevenueCycle.ManualStatementLedgerStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = RevenueCycle.newManualStatementLedger("code-1", name: "name-93")
        try item.moveTo(RevenueCycle.ManualStatementLedgerStatus.published)
        #expect(item.status == RevenueCycle.ManualStatementLedgerStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newManualStatementLedger("code-1", name: "name-93")
        item.status = RevenueCycle.ManualStatementLedgerStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ManualStatementLedgerStatus.created) }
    }
}
