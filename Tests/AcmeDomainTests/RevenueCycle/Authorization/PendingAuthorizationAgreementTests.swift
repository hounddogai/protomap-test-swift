@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingAuthorizationAgreementTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newPendingAuthorizationAgreement("code-148", title: "title-454")
        #expect(item.status == RevenueCycle.PendingAuthorizationAgreementStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = RevenueCycle.newPendingAuthorizationAgreement("code-148", title: "title-454")
        try item.moveTo(RevenueCycle.PendingAuthorizationAgreementStatus.archived)
        #expect(item.status == RevenueCycle.PendingAuthorizationAgreementStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newPendingAuthorizationAgreement("code-148", title: "title-454")
        item.status = RevenueCycle.PendingAuthorizationAgreementStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.PendingAuthorizationAgreementStatus.`open`) }
    }
}
