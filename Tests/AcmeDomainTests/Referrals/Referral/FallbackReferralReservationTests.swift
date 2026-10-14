@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackReferralReservationTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newFallbackReferralReservation("code-61", label: "label-959")
        #expect(item.status == Referrals.FallbackReferralReservationStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Referrals.newFallbackReferralReservation("code-61", label: "label-959")
        try item.moveTo(Referrals.FallbackReferralReservationStatus.pending)
        #expect(item.status == Referrals.FallbackReferralReservationStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newFallbackReferralReservation("code-61", label: "label-959")
        item.status = Referrals.FallbackReferralReservationStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FallbackReferralReservationStatus.draft) }
    }
}
