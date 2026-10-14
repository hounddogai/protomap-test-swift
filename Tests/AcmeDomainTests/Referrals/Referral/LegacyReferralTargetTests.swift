@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacyReferralTargetTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newLegacyReferralTarget("code-973", title: "title-487")
        #expect(item.status == Referrals.LegacyReferralTargetStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Referrals.newLegacyReferralTarget("code-973", title: "title-487")
        try item.moveTo(Referrals.LegacyReferralTargetStatus.reopened)
        #expect(item.status == Referrals.LegacyReferralTargetStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newLegacyReferralTarget("code-973", title: "title-487")
        item.status = Referrals.LegacyReferralTargetStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.LegacyReferralTargetStatus.`open`) }
    }
}
