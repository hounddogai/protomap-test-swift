@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralReservationTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newReferralReservation("code-294", label: "label-571")
        #expect(item.status == Referrals.ReferralReservationStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Referrals.newReferralReservation("code-294", label: "label-571")
        try item.moveTo(Referrals.ReferralReservationStatus.validated)
        #expect(item.status == Referrals.ReferralReservationStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newReferralReservation("code-294", label: "label-571")
        item.status = Referrals.ReferralReservationStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ReferralReservationStatus.created) }
    }
}
