@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementAgreementTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newStatementAgreement("code-933", name: "name-418")
        #expect(item.status == RevenueCycle.StatementAgreementStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = RevenueCycle.newStatementAgreement("code-933", name: "name-418")
        try item.moveTo(RevenueCycle.StatementAgreementStatus.suspended)
        #expect(item.status == RevenueCycle.StatementAgreementStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newStatementAgreement("code-933", name: "name-418")
        item.status = RevenueCycle.StatementAgreementStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StatementAgreementStatus.draft) }
    }
}
