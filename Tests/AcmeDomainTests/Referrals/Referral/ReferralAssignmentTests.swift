@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralAssignmentTests {
    @Test func startsInNew() throws {
        let item = Referrals.newReferralAssignment("code-34", title: "title-394")
        #expect(item.status == Referrals.ReferralAssignmentStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Referrals.newReferralAssignment("code-34", title: "title-394")
        try item.moveTo(Referrals.ReferralAssignmentStatus.failed)
        #expect(item.status == Referrals.ReferralAssignmentStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newReferralAssignment("code-34", title: "title-394")
        item.status = Referrals.ReferralAssignmentStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ReferralAssignmentStatus.new) }
    }
}
