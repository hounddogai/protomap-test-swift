@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientSpecimenReservationTests {
    @Test func startsInDraft() throws {
        let item = Labs.newLenientSpecimenReservation("code-772", label: "label-630")
        #expect(item.status == Labs.LenientSpecimenReservationStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Labs.newLenientSpecimenReservation("code-772", label: "label-630")
        try item.moveTo(Labs.LenientSpecimenReservationStatus.suspended)
        #expect(item.status == Labs.LenientSpecimenReservationStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newLenientSpecimenReservation("code-772", label: "label-630")
        item.status = Labs.LenientSpecimenReservationStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.LenientSpecimenReservationStatus.draft) }
    }
}
