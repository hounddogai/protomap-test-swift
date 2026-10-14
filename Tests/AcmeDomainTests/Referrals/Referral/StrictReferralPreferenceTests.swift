@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictReferralPreferenceTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newStrictReferralPreference("code-724", name: "name-878")
        #expect(item.status == Referrals.StrictReferralPreferenceStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Referrals.newStrictReferralPreference("code-724", name: "name-878")
        try item.moveTo(Referrals.StrictReferralPreferenceStatus.suspended)
        #expect(item.status == Referrals.StrictReferralPreferenceStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newStrictReferralPreference("code-724", name: "name-878")
        item.status = Referrals.StrictReferralPreferenceStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.StrictReferralPreferenceStatus.draft) }
    }
}
