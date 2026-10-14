@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingReadReservationTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newPendingReadReservation("code-781", label: "label-138")
        #expect(item.status == Imaging.PendingReadReservationStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Imaging.newPendingReadReservation("code-781", label: "label-138")
        try item.moveTo(Imaging.PendingReadReservationStatus.ready)
        #expect(item.status == Imaging.PendingReadReservationStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newPendingReadReservation("code-781", label: "label-138")
        item.status = Imaging.PendingReadReservationStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PendingReadReservationStatus.idle) }
    }
}
