@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelReservationTests {
    @Test func startsInOpen() throws {
        let item = Labs.newPanelReservation("code-935", title: "title-586")
        #expect(item.status == Labs.PanelReservationStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Labs.newPanelReservation("code-935", title: "title-586")
        try item.moveTo(Labs.PanelReservationStatus.inReview)
        #expect(item.status == Labs.PanelReservationStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newPanelReservation("code-935", title: "title-586")
        item.status = Labs.PanelReservationStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PanelReservationStatus.`open`) }
    }
}
