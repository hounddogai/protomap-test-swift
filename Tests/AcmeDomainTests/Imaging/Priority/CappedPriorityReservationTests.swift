@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCappedPriorityReservationTests {
    @Test func startsInNew() throws {
        let item = Imaging.newCappedPriorityReservation("code-862", label: "label-357")
        #expect(item.status == Imaging.CappedPriorityReservationStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Imaging.newCappedPriorityReservation("code-862", label: "label-357")
        try item.moveTo(Imaging.CappedPriorityReservationStatus.failed)
        #expect(item.status == Imaging.CappedPriorityReservationStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newCappedPriorityReservation("code-862", label: "label-357")
        item.status = Imaging.CappedPriorityReservationStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CappedPriorityReservationStatus.new) }
    }
}
