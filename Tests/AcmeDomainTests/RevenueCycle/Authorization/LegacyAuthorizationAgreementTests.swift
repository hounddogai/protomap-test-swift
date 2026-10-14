@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyAuthorizationAgreementTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newLegacyAuthorizationAgreement("code-357", title: "title-342")
        #expect(item.status == RevenueCycle.LegacyAuthorizationAgreementStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = RevenueCycle.newLegacyAuthorizationAgreement("code-357", title: "title-342")
        try item.moveTo(RevenueCycle.LegacyAuthorizationAgreementStatus.active)
        #expect(item.status == RevenueCycle.LegacyAuthorizationAgreementStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newLegacyAuthorizationAgreement("code-357", title: "title-342")
        item.status = RevenueCycle.LegacyAuthorizationAgreementStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.LegacyAuthorizationAgreementStatus.draft) }
    }
}
