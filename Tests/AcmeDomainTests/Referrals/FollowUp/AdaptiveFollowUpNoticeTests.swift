@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsAdaptiveFollowUpNoticeTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newAdaptiveFollowUpNotice("code-44", label: "label-559")
        #expect(item.status == Referrals.AdaptiveFollowUpNoticeStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Referrals.newAdaptiveFollowUpNotice("code-44", label: "label-559")
        try item.moveTo(Referrals.AdaptiveFollowUpNoticeStatus.reopened)
        #expect(item.status == Referrals.AdaptiveFollowUpNoticeStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newAdaptiveFollowUpNotice("code-44", label: "label-559")
        item.status = Referrals.AdaptiveFollowUpNoticeStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.AdaptiveFollowUpNoticeStatus.`open`) }
    }
}
