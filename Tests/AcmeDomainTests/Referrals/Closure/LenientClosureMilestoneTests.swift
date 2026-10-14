@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientClosureMilestoneTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newLenientClosureMilestone("code-153", title: "title-178")
        #expect(item.status == Referrals.LenientClosureMilestoneStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Referrals.newLenientClosureMilestone("code-153", title: "title-178")
        try item.moveTo(Referrals.LenientClosureMilestoneStatus.retired)
        #expect(item.status == Referrals.LenientClosureMilestoneStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newLenientClosureMilestone("code-153", title: "title-178")
        item.status = Referrals.LenientClosureMilestoneStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.LenientClosureMilestoneStatus.created) }
    }
}
