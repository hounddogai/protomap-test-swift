@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledFollowUpCycleTests {
    @Test func startsInNew() throws {
        let item = Referrals.newScheduledFollowUpCycle("code-214", title: "title-525")
        #expect(item.status == Referrals.ScheduledFollowUpCycleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Referrals.newScheduledFollowUpCycle("code-214", title: "title-525")
        try item.moveTo(Referrals.ScheduledFollowUpCycleStatus.queued)
        #expect(item.status == Referrals.ScheduledFollowUpCycleStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newScheduledFollowUpCycle("code-214", title: "title-525")
        item.status = Referrals.ScheduledFollowUpCycleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ScheduledFollowUpCycleStatus.new) }
    }
}
