@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementPolicyTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newStatementPolicy("code-663", title: "title-741")
        #expect(item.status == RevenueCycle.StatementPolicyStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = RevenueCycle.newStatementPolicy("code-663", title: "title-741")
        try item.moveTo(RevenueCycle.StatementPolicyStatus.active)
        #expect(item.status == RevenueCycle.StatementPolicyStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newStatementPolicy("code-663", title: "title-741")
        item.status = RevenueCycle.StatementPolicyStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StatementPolicyStatus.draft) }
    }
}
