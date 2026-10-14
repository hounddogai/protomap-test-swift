@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingStatementAgreementTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newPendingStatementAgreement("code-382", name: "name-884")
        #expect(item.status == RevenueCycle.PendingStatementAgreementStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = RevenueCycle.newPendingStatementAgreement("code-382", name: "name-884")
        try item.moveTo(RevenueCycle.PendingStatementAgreementStatus.published)
        #expect(item.status == RevenueCycle.PendingStatementAgreementStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newPendingStatementAgreement("code-382", name: "name-884")
        item.status = RevenueCycle.PendingStatementAgreementStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.PendingStatementAgreementStatus.created) }
    }
}
