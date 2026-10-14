@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLenientRemittanceReservationTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newLenientRemittanceReservation("code-208", label: "label-40")
        #expect(item.status == RevenueCycle.LenientRemittanceReservationStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = RevenueCycle.newLenientRemittanceReservation("code-208", label: "label-40")
        try item.moveTo(RevenueCycle.LenientRemittanceReservationStatus.queued)
        #expect(item.status == RevenueCycle.LenientRemittanceReservationStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newLenientRemittanceReservation("code-208", label: "label-40")
        item.status = RevenueCycle.LenientRemittanceReservationStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.LenientRemittanceReservationStatus.new) }
    }
}
