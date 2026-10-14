@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingAuthorizationPreferenceTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newPendingAuthorizationPreference("code-391", label: "label-803")
        #expect(item.status == RevenueCycle.PendingAuthorizationPreferenceStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = RevenueCycle.newPendingAuthorizationPreference("code-391", label: "label-803")
        try item.moveTo(RevenueCycle.PendingAuthorizationPreferenceStatus.pending)
        #expect(item.status == RevenueCycle.PendingAuthorizationPreferenceStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newPendingAuthorizationPreference("code-391", label: "label-803")
        item.status = RevenueCycle.PendingAuthorizationPreferenceStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.PendingAuthorizationPreferenceStatus.draft) }
    }
}
