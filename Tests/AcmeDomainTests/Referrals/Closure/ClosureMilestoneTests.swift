@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureMilestoneTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newClosureMilestone("code-19", title: "title-671")
        #expect(item.status == Referrals.ClosureMilestoneStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Referrals.newClosureMilestone("code-19", title: "title-671")
        try item.moveTo(Referrals.ClosureMilestoneStatus.pending)
        #expect(item.status == Referrals.ClosureMilestoneStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newClosureMilestone("code-19", title: "title-671")
        item.status = Referrals.ClosureMilestoneStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ClosureMilestoneStatus.draft) }
    }
}
