@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityNoticeTests {
    @Test func startsInNew() throws {
        let item = Referrals.newEligibilityNotice("code-391", name: "name-555")
        #expect(item.status == Referrals.EligibilityNoticeStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Referrals.newEligibilityNotice("code-391", name: "name-555")
        try item.moveTo(Referrals.EligibilityNoticeStatus.queued)
        #expect(item.status == Referrals.EligibilityNoticeStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newEligibilityNotice("code-391", name: "name-555")
        item.status = Referrals.EligibilityNoticeStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.EligibilityNoticeStatus.new) }
    }
}
