@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpReservationTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newFollowUpReservation("code-579", name: "name-106")
        #expect(item.status == Referrals.FollowUpReservationStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Referrals.newFollowUpReservation("code-579", name: "name-106")
        try item.moveTo(Referrals.FollowUpReservationStatus.granted)
        #expect(item.status == Referrals.FollowUpReservationStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newFollowUpReservation("code-579", name: "name-106")
        item.status = Referrals.FollowUpReservationStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FollowUpReservationStatus.requested) }
    }
}
