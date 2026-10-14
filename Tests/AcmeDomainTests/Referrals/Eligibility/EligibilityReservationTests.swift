@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityReservationTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newEligibilityReservation("code-190", name: "name-866")
        #expect(item.status == Referrals.EligibilityReservationStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newEligibilityReservation("code-190", name: "name-866")
        try item.moveTo(Referrals.EligibilityReservationStatus.approved)
        #expect(item.status == Referrals.EligibilityReservationStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newEligibilityReservation("code-190", name: "name-866")
        item.status = Referrals.EligibilityReservationStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.EligibilityReservationStatus.proposed) }
    }
}
