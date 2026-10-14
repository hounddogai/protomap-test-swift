@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimReservationTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newClaimReservation("code-370", label: "label-323")
        #expect(item.status == RevenueCycle.ClaimReservationStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = RevenueCycle.newClaimReservation("code-370", label: "label-323")
        try item.moveTo(RevenueCycle.ClaimReservationStatus.pending)
        #expect(item.status == RevenueCycle.ClaimReservationStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newClaimReservation("code-370", label: "label-323")
        item.status = RevenueCycle.ClaimReservationStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ClaimReservationStatus.draft) }
    }
}
