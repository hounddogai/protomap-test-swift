@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingFollowUpReservationTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newPendingFollowUpReservation("code-375", label: "label-87")
        #expect(item.status == Referrals.PendingFollowUpReservationStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Referrals.newPendingFollowUpReservation("code-375", label: "label-87")
        try item.moveTo(Referrals.PendingFollowUpReservationStatus.scheduled)
        #expect(item.status == Referrals.PendingFollowUpReservationStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newPendingFollowUpReservation("code-375", label: "label-87")
        item.status = Referrals.PendingFollowUpReservationStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.PendingFollowUpReservationStatus.planned) }
    }
}
