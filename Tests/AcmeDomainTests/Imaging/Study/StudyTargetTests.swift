@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyTargetTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newStudyTarget("code-173", label: "label-386")
        #expect(item.status == Imaging.StudyTargetStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Imaging.newStudyTarget("code-173", label: "label-386")
        try item.moveTo(Imaging.StudyTargetStatus.retired)
        #expect(item.status == Imaging.StudyTargetStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newStudyTarget("code-173", label: "label-386")
        item.status = Imaging.StudyTargetStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StudyTargetStatus.created) }
    }
}
