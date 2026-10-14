@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralPreferenceTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newReferralPreference("code-973", title: "title-155")
        #expect(item.status == Referrals.ReferralPreferenceStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Referrals.newReferralPreference("code-973", title: "title-155")
        try item.moveTo(Referrals.ReferralPreferenceStatus.inReview)
        #expect(item.status == Referrals.ReferralPreferenceStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newReferralPreference("code-973", title: "title-155")
        item.status = Referrals.ReferralPreferenceStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ReferralPreferenceStatus.`open`) }
    }
}
