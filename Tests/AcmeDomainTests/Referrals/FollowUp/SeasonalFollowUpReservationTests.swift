@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalFollowUpReservationTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newSeasonalFollowUpReservation("code-712", name: "name-633")
        #expect(item.status == Referrals.SeasonalFollowUpReservationStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Referrals.newSeasonalFollowUpReservation("code-712", name: "name-633")
        try item.moveTo(Referrals.SeasonalFollowUpReservationStatus.inProgress)
        #expect(item.status == Referrals.SeasonalFollowUpReservationStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newSeasonalFollowUpReservation("code-712", name: "name-633")
        item.status = Referrals.SeasonalFollowUpReservationStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SeasonalFollowUpReservationStatus.planned) }
    }
}
