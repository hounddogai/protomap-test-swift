@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictSlotAssignmentTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newStrictSlotAssignment("code-650", name: "name-497")
        #expect(item.status == Referrals.StrictSlotAssignmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Referrals.newStrictSlotAssignment("code-650", name: "name-497")
        try item.moveTo(Referrals.StrictSlotAssignmentStatus.pending)
        #expect(item.status == Referrals.StrictSlotAssignmentStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newStrictSlotAssignment("code-650", name: "name-497")
        item.status = Referrals.StrictSlotAssignmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.StrictSlotAssignmentStatus.draft) }
    }
}
