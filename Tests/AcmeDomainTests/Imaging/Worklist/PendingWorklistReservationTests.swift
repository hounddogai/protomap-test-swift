@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingWorklistReservationTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newPendingWorklistReservation("code-569", title: "title-816")
        #expect(item.status == Imaging.PendingWorklistReservationStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Imaging.newPendingWorklistReservation("code-569", title: "title-816")
        try item.moveTo(Imaging.PendingWorklistReservationStatus.active)
        #expect(item.status == Imaging.PendingWorklistReservationStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newPendingWorklistReservation("code-569", title: "title-816")
        item.status = Imaging.PendingWorklistReservationStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PendingWorklistReservationStatus.draft) }
    }
}
