@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultReservationTests {
    @Test func startsInNew() throws {
        let item = Labs.newResultReservation("code-473", label: "label-803")
        #expect(item.status == Labs.ResultReservationStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Labs.newResultReservation("code-473", label: "label-803")
        try item.moveTo(Labs.ResultReservationStatus.queued)
        #expect(item.status == Labs.ResultReservationStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newResultReservation("code-473", label: "label-803")
        item.status = Labs.ResultReservationStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ResultReservationStatus.new) }
    }
}
