@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimPreferenceTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newClaimPreference("code-190", label: "label-894")
        #expect(item.status == RevenueCycle.ClaimPreferenceStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = RevenueCycle.newClaimPreference("code-190", label: "label-894")
        try item.moveTo(RevenueCycle.ClaimPreferenceStatus.active)
        #expect(item.status == RevenueCycle.ClaimPreferenceStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newClaimPreference("code-190", label: "label-894")
        item.status = RevenueCycle.ClaimPreferenceStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ClaimPreferenceStatus.draft) }
    }
}
