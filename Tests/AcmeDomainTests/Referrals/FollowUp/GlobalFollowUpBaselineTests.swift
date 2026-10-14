@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalFollowUpBaselineTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newGlobalFollowUpBaseline("code-871", label: "label-438")
        #expect(item.status == Referrals.GlobalFollowUpBaselineStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Referrals.newGlobalFollowUpBaseline("code-871", label: "label-438")
        try item.moveTo(Referrals.GlobalFollowUpBaselineStatus.expired)
        #expect(item.status == Referrals.GlobalFollowUpBaselineStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newGlobalFollowUpBaseline("code-871", label: "label-438")
        item.status = Referrals.GlobalFollowUpBaselineStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.GlobalFollowUpBaselineStatus.requested) }
    }
}
