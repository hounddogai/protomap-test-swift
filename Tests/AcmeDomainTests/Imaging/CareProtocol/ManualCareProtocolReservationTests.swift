@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualCareProtocolReservationTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newManualCareProtocolReservation("code-603", label: "label-531")
        #expect(item.status == Imaging.ManualCareProtocolReservationStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Imaging.newManualCareProtocolReservation("code-603", label: "label-531")
        try item.moveTo(Imaging.ManualCareProtocolReservationStatus.granted)
        #expect(item.status == Imaging.ManualCareProtocolReservationStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newManualCareProtocolReservation("code-603", label: "label-531")
        item.status = Imaging.ManualCareProtocolReservationStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ManualCareProtocolReservationStatus.requested) }
    }
}
