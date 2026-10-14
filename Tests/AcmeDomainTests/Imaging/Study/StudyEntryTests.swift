@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyEntryTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newStudyEntry("code-633", title: "title-601")
        #expect(item.status == Imaging.StudyEntryStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Imaging.newStudyEntry("code-633", title: "title-601")
        try item.moveTo(Imaging.StudyEntryStatus.approved)
        #expect(item.status == Imaging.StudyEntryStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newStudyEntry("code-633", title: "title-601")
        item.status = Imaging.StudyEntryStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StudyEntryStatus.proposed) }
    }
}
