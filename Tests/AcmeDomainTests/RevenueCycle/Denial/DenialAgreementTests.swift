@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialAgreementTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newDenialAgreement("code-149", title: "title-639")
        #expect(item.status == RevenueCycle.DenialAgreementStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = RevenueCycle.newDenialAgreement("code-149", title: "title-639")
        try item.moveTo(RevenueCycle.DenialAgreementStatus.scheduled)
        #expect(item.status == RevenueCycle.DenialAgreementStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newDenialAgreement("code-149", title: "title-639")
        item.status = RevenueCycle.DenialAgreementStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DenialAgreementStatus.planned) }
    }
}
