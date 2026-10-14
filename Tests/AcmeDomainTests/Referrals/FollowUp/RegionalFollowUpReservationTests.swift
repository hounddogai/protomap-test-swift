@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalFollowUpReservationTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newRegionalFollowUpReservation("code-22", name: "name-758")
        #expect(item.status == Referrals.RegionalFollowUpReservationStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Referrals.newRegionalFollowUpReservation("code-22", name: "name-758")
        try item.moveTo(Referrals.RegionalFollowUpReservationStatus.rejected)
        #expect(item.status == Referrals.RegionalFollowUpReservationStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newRegionalFollowUpReservation("code-22", name: "name-758")
        item.status = Referrals.RegionalFollowUpReservationStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.RegionalFollowUpReservationStatus.proposed) }
    }
}
