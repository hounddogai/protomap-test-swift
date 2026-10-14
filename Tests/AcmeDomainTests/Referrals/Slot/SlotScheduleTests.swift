@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotScheduleTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newSlotSchedule("code-827", title: "title-982")
        #expect(item.status == Referrals.SlotScheduleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newSlotSchedule("code-827", title: "title-982")
        try item.moveTo(Referrals.SlotScheduleStatus.approved)
        #expect(item.status == Referrals.SlotScheduleStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newSlotSchedule("code-827", title: "title-982")
        item.status = Referrals.SlotScheduleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SlotScheduleStatus.proposed) }
    }
}
