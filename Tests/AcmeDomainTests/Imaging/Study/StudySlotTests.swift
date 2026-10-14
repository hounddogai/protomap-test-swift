@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudySlotTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newStudySlot("code-486", title: "title-49")
        #expect(item.status == Imaging.StudySlotStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Imaging.newStudySlot("code-486", title: "title-49")
        try item.moveTo(Imaging.StudySlotStatus.cancelled)
        #expect(item.status == Imaging.StudySlotStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newStudySlot("code-486", title: "title-49")
        item.status = Imaging.StudySlotStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StudySlotStatus.planned) }
    }
}
