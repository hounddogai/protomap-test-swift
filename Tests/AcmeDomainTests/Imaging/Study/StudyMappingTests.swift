@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyMappingTests {
    @Test func startsInNew() throws {
        let item = Imaging.newStudyMapping("code-992", label: "label-574")
        #expect(item.status == Imaging.StudyMappingStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Imaging.newStudyMapping("code-992", label: "label-574")
        try item.moveTo(Imaging.StudyMappingStatus.running)
        #expect(item.status == Imaging.StudyMappingStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newStudyMapping("code-992", label: "label-574")
        item.status = Imaging.StudyMappingStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StudyMappingStatus.new) }
    }
}
