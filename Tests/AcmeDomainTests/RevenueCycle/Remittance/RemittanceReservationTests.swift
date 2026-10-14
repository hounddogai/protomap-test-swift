@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceReservationTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newRemittanceReservation("code-888", label: "label-189")
        #expect(item.status == RevenueCycle.RemittanceReservationStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = RevenueCycle.newRemittanceReservation("code-888", label: "label-189")
        try item.moveTo(RevenueCycle.RemittanceReservationStatus.validated)
        #expect(item.status == RevenueCycle.RemittanceReservationStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newRemittanceReservation("code-888", label: "label-189")
        item.status = RevenueCycle.RemittanceReservationStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittanceReservationStatus.created) }
    }
}
