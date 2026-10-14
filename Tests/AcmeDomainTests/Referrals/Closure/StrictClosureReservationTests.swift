@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictClosureReservationTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newStrictClosureReservation("code-38", label: "label-537")
        #expect(item.status == Referrals.StrictClosureReservationStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Referrals.newStrictClosureReservation("code-38", label: "label-537")
        try item.moveTo(Referrals.StrictClosureReservationStatus.reopened)
        #expect(item.status == Referrals.StrictClosureReservationStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newStrictClosureReservation("code-38", label: "label-537")
        item.status = Referrals.StrictClosureReservationStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.StrictClosureReservationStatus.`open`) }
    }
}
