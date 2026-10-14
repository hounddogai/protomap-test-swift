@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalAccessionReservationTests {
    @Test func startsInDraft() throws {
        let item = Labs.newRegionalAccessionReservation("code-951", label: "label-668")
        #expect(item.status == Labs.RegionalAccessionReservationStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Labs.newRegionalAccessionReservation("code-951", label: "label-668")
        try item.moveTo(Labs.RegionalAccessionReservationStatus.pending)
        #expect(item.status == Labs.RegionalAccessionReservationStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newRegionalAccessionReservation("code-951", label: "label-668")
        item.status = Labs.RegionalAccessionReservationStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.RegionalAccessionReservationStatus.draft) }
    }
}
