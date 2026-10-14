@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredPriorityReservationTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newTieredPriorityReservation("code-825", title: "title-940")
        #expect(item.status == Imaging.TieredPriorityReservationStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Imaging.newTieredPriorityReservation("code-825", title: "title-940")
        try item.moveTo(Imaging.TieredPriorityReservationStatus.reopened)
        #expect(item.status == Imaging.TieredPriorityReservationStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newTieredPriorityReservation("code-825", title: "title-940")
        item.status = Imaging.TieredPriorityReservationStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.TieredPriorityReservationStatus.`open`) }
    }
}
