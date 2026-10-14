@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedFollowUpAssignmentTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newWeightedFollowUpAssignment("code-43", label: "label-943")
        #expect(item.status == Referrals.WeightedFollowUpAssignmentStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Referrals.newWeightedFollowUpAssignment("code-43", label: "label-943")
        try item.moveTo(Referrals.WeightedFollowUpAssignmentStatus.rejected)
        #expect(item.status == Referrals.WeightedFollowUpAssignmentStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newWeightedFollowUpAssignment("code-43", label: "label-943")
        item.status = Referrals.WeightedFollowUpAssignmentStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.WeightedFollowUpAssignmentStatus.proposed) }
    }
}
