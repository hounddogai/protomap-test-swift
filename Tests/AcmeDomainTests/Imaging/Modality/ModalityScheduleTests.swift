@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityScheduleTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newModalitySchedule("code-25", name: "name-979")
        #expect(item.status == Imaging.ModalityScheduleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Imaging.newModalitySchedule("code-25", name: "name-979")
        try item.moveTo(Imaging.ModalityScheduleStatus.pending)
        #expect(item.status == Imaging.ModalityScheduleStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newModalitySchedule("code-25", name: "name-979")
        item.status = Imaging.ModalityScheduleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalityScheduleStatus.draft) }
    }
}
