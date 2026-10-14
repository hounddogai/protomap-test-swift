@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualDenialAgreementTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newManualDenialAgreement("code-198", name: "name-742")
        #expect(item.status == RevenueCycle.ManualDenialAgreementStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = RevenueCycle.newManualDenialAgreement("code-198", name: "name-742")
        try item.moveTo(RevenueCycle.ManualDenialAgreementStatus.suspended)
        #expect(item.status == RevenueCycle.ManualDenialAgreementStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newManualDenialAgreement("code-198", name: "name-742")
        item.status = RevenueCycle.ManualDenialAgreementStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ManualDenialAgreementStatus.draft) }
    }
}
