@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingBatchedCareProtocolReservationTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newBatchedCareProtocolReservation("code-637", name: "name-223")
        #expect(item.status == Imaging.BatchedCareProtocolReservationStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Imaging.newBatchedCareProtocolReservation("code-637", name: "name-223")
        try item.moveTo(Imaging.BatchedCareProtocolReservationStatus.stopped)
        #expect(item.status == Imaging.BatchedCareProtocolReservationStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newBatchedCareProtocolReservation("code-637", name: "name-223")
        item.status = Imaging.BatchedCareProtocolReservationStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.BatchedCareProtocolReservationStatus.idle) }
    }
}
