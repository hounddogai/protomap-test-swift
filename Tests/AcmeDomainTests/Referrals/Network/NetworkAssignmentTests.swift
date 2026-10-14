@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkAssignmentTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newNetworkAssignment("code-175", label: "label-163")
        #expect(item.status == Referrals.NetworkAssignmentStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newNetworkAssignment("code-175", label: "label-163")
        try item.moveTo(Referrals.NetworkAssignmentStatus.approved)
        #expect(item.status == Referrals.NetworkAssignmentStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newNetworkAssignment("code-175", label: "label-163")
        item.status = Referrals.NetworkAssignmentStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.NetworkAssignmentStatus.proposed) }
    }
}
