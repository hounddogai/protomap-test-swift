@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacyReferralAssignmentTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newLegacyReferralAssignment("code-955", name: "name-79")
        #expect(item.status == Referrals.LegacyReferralAssignmentStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Referrals.newLegacyReferralAssignment("code-955", name: "name-79")
        try item.moveTo(Referrals.LegacyReferralAssignmentStatus.validated)
        #expect(item.status == Referrals.LegacyReferralAssignmentStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newLegacyReferralAssignment("code-955", name: "name-79")
        item.status = Referrals.LegacyReferralAssignmentStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.LegacyReferralAssignmentStatus.created) }
    }
}
