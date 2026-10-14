@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultSpecimenReservationTests {
    @Test func startsInIdle() throws {
        let item = Labs.newDefaultSpecimenReservation("code-395", label: "label-367")
        #expect(item.status == Labs.DefaultSpecimenReservationStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Labs.newDefaultSpecimenReservation("code-395", label: "label-367")
        try item.moveTo(Labs.DefaultSpecimenReservationStatus.stopped)
        #expect(item.status == Labs.DefaultSpecimenReservationStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newDefaultSpecimenReservation("code-395", label: "label-367")
        item.status = Labs.DefaultSpecimenReservationStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.DefaultSpecimenReservationStatus.idle) }
    }
}
