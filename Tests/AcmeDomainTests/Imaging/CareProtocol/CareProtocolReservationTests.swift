@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolReservationTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newCareProtocolReservation("code-320", title: "title-319")
        #expect(item.status == Imaging.CareProtocolReservationStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Imaging.newCareProtocolReservation("code-320", title: "title-319")
        try item.moveTo(Imaging.CareProtocolReservationStatus.granted)
        #expect(item.status == Imaging.CareProtocolReservationStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newCareProtocolReservation("code-320", title: "title-319")
        item.status = Imaging.CareProtocolReservationStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CareProtocolReservationStatus.requested) }
    }
}
