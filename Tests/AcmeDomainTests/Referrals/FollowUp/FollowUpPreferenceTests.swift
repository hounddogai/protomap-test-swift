@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpPreferenceTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newFollowUpPreference("code-265", name: "name-485")
        #expect(item.status == Referrals.FollowUpPreferenceStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Referrals.newFollowUpPreference("code-265", name: "name-485")
        try item.moveTo(Referrals.FollowUpPreferenceStatus.cancelled)
        #expect(item.status == Referrals.FollowUpPreferenceStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newFollowUpPreference("code-265", name: "name-485")
        item.status = Referrals.FollowUpPreferenceStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FollowUpPreferenceStatus.planned) }
    }
}
