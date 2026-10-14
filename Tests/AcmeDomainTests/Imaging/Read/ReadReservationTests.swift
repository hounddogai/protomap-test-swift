@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadReservationTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newReadReservation("code-342", label: "label-456")
        #expect(item.status == Imaging.ReadReservationStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Imaging.newReadReservation("code-342", label: "label-456")
        try item.moveTo(Imaging.ReadReservationStatus.retired)
        #expect(item.status == Imaging.ReadReservationStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newReadReservation("code-342", label: "label-456")
        item.status = Imaging.ReadReservationStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ReadReservationStatus.created) }
    }
}
