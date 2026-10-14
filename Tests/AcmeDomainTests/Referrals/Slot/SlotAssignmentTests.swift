@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotAssignmentTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newSlotAssignment("code-876", label: "label-324")
        #expect(item.status == Referrals.SlotAssignmentStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Referrals.newSlotAssignment("code-876", label: "label-324")
        try item.moveTo(Referrals.SlotAssignmentStatus.ready)
        #expect(item.status == Referrals.SlotAssignmentStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newSlotAssignment("code-876", label: "label-324")
        item.status = Referrals.SlotAssignmentStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SlotAssignmentStatus.idle) }
    }
}
