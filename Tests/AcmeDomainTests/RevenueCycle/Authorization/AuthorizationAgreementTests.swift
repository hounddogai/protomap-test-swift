@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationAgreementTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newAuthorizationAgreement("code-54", name: "name-173")
        #expect(item.status == RevenueCycle.AuthorizationAgreementStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = RevenueCycle.newAuthorizationAgreement("code-54", name: "name-173")
        try item.moveTo(RevenueCycle.AuthorizationAgreementStatus.active)
        #expect(item.status == RevenueCycle.AuthorizationAgreementStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newAuthorizationAgreement("code-54", name: "name-173")
        item.status = RevenueCycle.AuthorizationAgreementStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AuthorizationAgreementStatus.draft) }
    }
}
