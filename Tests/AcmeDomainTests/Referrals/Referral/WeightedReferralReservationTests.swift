@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedReferralReservationTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newWeightedReferralReservation("code-339", title: "title-160")
        #expect(item.status == Referrals.WeightedReferralReservationStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Referrals.newWeightedReferralReservation("code-339", title: "title-160")
        try item.moveTo(Referrals.WeightedReferralReservationStatus.revoked)
        #expect(item.status == Referrals.WeightedReferralReservationStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newWeightedReferralReservation("code-339", title: "title-160")
        item.status = Referrals.WeightedReferralReservationStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.WeightedReferralReservationStatus.requested) }
    }
}
