@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleCappedClaimReservationTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newCappedClaimReservation("code-648", label: "label-312")
        #expect(item.status == RevenueCycle.CappedClaimReservationStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = RevenueCycle.newCappedClaimReservation("code-648", label: "label-312")
        try item.moveTo(RevenueCycle.CappedClaimReservationStatus.cancelled)
        #expect(item.status == RevenueCycle.CappedClaimReservationStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newCappedClaimReservation("code-648", label: "label-312")
        item.status = RevenueCycle.CappedClaimReservationStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.CappedClaimReservationStatus.planned) }
    }
}
