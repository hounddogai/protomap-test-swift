@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotMilestoneTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newSlotMilestone("code-452", name: "name-887")
        #expect(item.status == Referrals.SlotMilestoneStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Referrals.newSlotMilestone("code-452", name: "name-887")
        try item.moveTo(Referrals.SlotMilestoneStatus.archived)
        #expect(item.status == Referrals.SlotMilestoneStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newSlotMilestone("code-452", name: "name-887")
        item.status = Referrals.SlotMilestoneStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SlotMilestoneStatus.`open`) }
    }
}
