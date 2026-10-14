@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptiveCareProtocolReservationTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newAdaptiveCareProtocolReservation("code-731", name: "name-232")
        #expect(item.status == Imaging.AdaptiveCareProtocolReservationStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Imaging.newAdaptiveCareProtocolReservation("code-731", name: "name-232")
        try item.moveTo(Imaging.AdaptiveCareProtocolReservationStatus.granted)
        #expect(item.status == Imaging.AdaptiveCareProtocolReservationStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newAdaptiveCareProtocolReservation("code-731", name: "name-232")
        item.status = Imaging.AdaptiveCareProtocolReservationStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.AdaptiveCareProtocolReservationStatus.requested) }
    }
}
