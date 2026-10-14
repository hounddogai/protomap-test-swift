@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenReservationTests {
    @Test func startsInCreated() throws {
        let item = Labs.newSpecimenReservation("code-713", title: "title-227")
        #expect(item.status == Labs.SpecimenReservationStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Labs.newSpecimenReservation("code-713", title: "title-227")
        try item.moveTo(Labs.SpecimenReservationStatus.validated)
        #expect(item.status == Labs.SpecimenReservationStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newSpecimenReservation("code-713", title: "title-227")
        item.status = Labs.SpecimenReservationStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SpecimenReservationStatus.created) }
    }
}
