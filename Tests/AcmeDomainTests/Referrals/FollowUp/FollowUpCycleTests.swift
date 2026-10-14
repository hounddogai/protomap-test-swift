@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpCycleTests {
    @Test func startsInNew() throws {
        let item = Referrals.newFollowUpCycle("code-827", label: "label-429")
        #expect(item.status == Referrals.FollowUpCycleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Referrals.newFollowUpCycle("code-827", label: "label-429")
        try item.moveTo(Referrals.FollowUpCycleStatus.failed)
        #expect(item.status == Referrals.FollowUpCycleStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newFollowUpCycle("code-827", label: "label-429")
        item.status = Referrals.FollowUpCycleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FollowUpCycleStatus.new) }
    }
}
