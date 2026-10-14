@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementTierTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newStatementTier("code-897", name: "name-368")
        #expect(item.status == RevenueCycle.StatementTierStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = RevenueCycle.newStatementTier("code-897", name: "name-368")
        try item.moveTo(RevenueCycle.StatementTierStatus.pending)
        #expect(item.status == RevenueCycle.StatementTierStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newStatementTier("code-897", name: "name-368")
        item.status = RevenueCycle.StatementTierStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StatementTierStatus.draft) }
    }
}
