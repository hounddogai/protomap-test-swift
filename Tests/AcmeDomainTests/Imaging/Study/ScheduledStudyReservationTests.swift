@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledStudyReservationTests {
    @Test func startsInNew() throws {
        let item = Imaging.newScheduledStudyReservation("code-941", label: "label-96")
        #expect(item.status == Imaging.ScheduledStudyReservationStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Imaging.newScheduledStudyReservation("code-941", label: "label-96")
        try item.moveTo(Imaging.ScheduledStudyReservationStatus.done)
        #expect(item.status == Imaging.ScheduledStudyReservationStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newScheduledStudyReservation("code-941", label: "label-96")
        item.status = Imaging.ScheduledStudyReservationStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ScheduledStudyReservationStatus.new) }
    }
}
