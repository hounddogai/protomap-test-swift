@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredFollowUpReservationTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newTieredFollowUpReservation("code-173", label: "label-886")
        #expect(item.status == Referrals.TieredFollowUpReservationStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Referrals.newTieredFollowUpReservation("code-173", label: "label-886")
        try item.moveTo(Referrals.TieredFollowUpReservationStatus.expired)
        #expect(item.status == Referrals.TieredFollowUpReservationStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newTieredFollowUpReservation("code-173", label: "label-886")
        item.status = Referrals.TieredFollowUpReservationStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.TieredFollowUpReservationStatus.requested) }
    }
}
