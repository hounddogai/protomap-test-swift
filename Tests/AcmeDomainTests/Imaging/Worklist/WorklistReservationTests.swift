@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistReservationTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newWorklistReservation("code-98", title: "title-943")
        #expect(item.status == Imaging.WorklistReservationStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Imaging.newWorklistReservation("code-98", title: "title-943")
        try item.moveTo(Imaging.WorklistReservationStatus.withdrawn)
        #expect(item.status == Imaging.WorklistReservationStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newWorklistReservation("code-98", title: "title-943")
        item.status = Imaging.WorklistReservationStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WorklistReservationStatus.proposed) }
    }
}
