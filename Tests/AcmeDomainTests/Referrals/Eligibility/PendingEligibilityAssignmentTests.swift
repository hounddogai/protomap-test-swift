@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingEligibilityAssignmentTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newPendingEligibilityAssignment("code-471", title: "title-33")
        #expect(item.status == Referrals.PendingEligibilityAssignmentStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Referrals.newPendingEligibilityAssignment("code-471", title: "title-33")
        try item.moveTo(Referrals.PendingEligibilityAssignmentStatus.scheduled)
        #expect(item.status == Referrals.PendingEligibilityAssignmentStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newPendingEligibilityAssignment("code-471", title: "title-33")
        item.status = Referrals.PendingEligibilityAssignmentStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.PendingEligibilityAssignmentStatus.planned) }
    }
}
