@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceAgreementTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newRemittanceAgreement("code-535", title: "title-306")
        #expect(item.status == RevenueCycle.RemittanceAgreementStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = RevenueCycle.newRemittanceAgreement("code-535", title: "title-306")
        try item.moveTo(RevenueCycle.RemittanceAgreementStatus.granted)
        #expect(item.status == RevenueCycle.RemittanceAgreementStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newRemittanceAgreement("code-535", title: "title-306")
        item.status = RevenueCycle.RemittanceAgreementStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittanceAgreementStatus.requested) }
    }
}
