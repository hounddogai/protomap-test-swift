@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkReservationTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newNetworkReservation("code-506", title: "title-989")
        #expect(item.status == Referrals.NetworkReservationStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Referrals.newNetworkReservation("code-506", title: "title-989")
        try item.moveTo(Referrals.NetworkReservationStatus.validated)
        #expect(item.status == Referrals.NetworkReservationStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newNetworkReservation("code-506", title: "title-989")
        item.status = Referrals.NetworkReservationStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.NetworkReservationStatus.created) }
    }
}
