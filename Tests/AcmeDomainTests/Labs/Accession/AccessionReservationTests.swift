@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionReservationTests {
    @Test func startsInOpen() throws {
        let item = Labs.newAccessionReservation("code-978", label: "label-337")
        #expect(item.status == Labs.AccessionReservationStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Labs.newAccessionReservation("code-978", label: "label-337")
        try item.moveTo(Labs.AccessionReservationStatus.archived)
        #expect(item.status == Labs.AccessionReservationStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newAccessionReservation("code-978", label: "label-337")
        item.status = Labs.AccessionReservationStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AccessionReservationStatus.`open`) }
    }
}
