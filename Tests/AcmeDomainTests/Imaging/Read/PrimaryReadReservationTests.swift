@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryReadReservationTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newPrimaryReadReservation("code-711", title: "title-934")
        #expect(item.status == Imaging.PrimaryReadReservationStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Imaging.newPrimaryReadReservation("code-711", title: "title-934")
        try item.moveTo(Imaging.PrimaryReadReservationStatus.granted)
        #expect(item.status == Imaging.PrimaryReadReservationStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newPrimaryReadReservation("code-711", title: "title-934")
        item.status = Imaging.PrimaryReadReservationStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PrimaryReadReservationStatus.requested) }
    }
}
