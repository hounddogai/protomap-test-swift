@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedClosureMilestoneTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newCappedClosureMilestone("code-821", name: "name-90")
        #expect(item.status == Referrals.CappedClosureMilestoneStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Referrals.newCappedClosureMilestone("code-821", name: "name-90")
        try item.moveTo(Referrals.CappedClosureMilestoneStatus.inReview)
        #expect(item.status == Referrals.CappedClosureMilestoneStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newCappedClosureMilestone("code-821", name: "name-90")
        item.status = Referrals.CappedClosureMilestoneStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.CappedClosureMilestoneStatus.`open`) }
    }
}
