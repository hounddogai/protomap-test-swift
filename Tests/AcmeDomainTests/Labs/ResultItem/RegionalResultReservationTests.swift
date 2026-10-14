@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalResultReservationTests {
    @Test func startsInRequested() throws {
        let item = Labs.newRegionalResultReservation("code-649", label: "label-356")
        #expect(item.status == Labs.RegionalResultReservationStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Labs.newRegionalResultReservation("code-649", label: "label-356")
        try item.moveTo(Labs.RegionalResultReservationStatus.revoked)
        #expect(item.status == Labs.RegionalResultReservationStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newRegionalResultReservation("code-649", label: "label-356")
        item.status = Labs.RegionalResultReservationStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.RegionalResultReservationStatus.requested) }
    }
}
