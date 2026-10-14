@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudySnapshotTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newStudySnapshot("code-138", name: "name-395")
        #expect(item.status == Imaging.StudySnapshotStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Imaging.newStudySnapshot("code-138", name: "name-395")
        try item.moveTo(Imaging.StudySnapshotStatus.validated)
        #expect(item.status == Imaging.StudySnapshotStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newStudySnapshot("code-138", name: "name-395")
        item.status = Imaging.StudySnapshotStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StudySnapshotStatus.created) }
    }
}
