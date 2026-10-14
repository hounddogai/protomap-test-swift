@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingEligibilityPreferenceTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newPendingEligibilityPreference("code-440", title: "title-453")
        #expect(item.status == Referrals.PendingEligibilityPreferenceStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Referrals.newPendingEligibilityPreference("code-440", title: "title-453")
        try item.moveTo(Referrals.PendingEligibilityPreferenceStatus.granted)
        #expect(item.status == Referrals.PendingEligibilityPreferenceStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newPendingEligibilityPreference("code-440", title: "title-453")
        item.status = Referrals.PendingEligibilityPreferenceStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.PendingEligibilityPreferenceStatus.requested) }
    }
}
