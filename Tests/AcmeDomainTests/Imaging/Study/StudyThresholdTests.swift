@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyThresholdTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newStudyThreshold("code-610", name: "name-193")
        #expect(item.status == Imaging.StudyThresholdStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Imaging.newStudyThreshold("code-610", name: "name-193")
        try item.moveTo(Imaging.StudyThresholdStatus.warming)
        #expect(item.status == Imaging.StudyThresholdStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newStudyThreshold("code-610", name: "name-193")
        item.status = Imaging.StudyThresholdStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StudyThresholdStatus.idle) }
    }
}
