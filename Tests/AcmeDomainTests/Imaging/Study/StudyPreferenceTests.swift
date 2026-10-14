@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyPreferenceTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newStudyPreference("code-145", name: "name-587")
        #expect(item.status == Imaging.StudyPreferenceStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Imaging.newStudyPreference("code-145", name: "name-587")
        try item.moveTo(Imaging.StudyPreferenceStatus.suspended)
        #expect(item.status == Imaging.StudyPreferenceStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newStudyPreference("code-145", name: "name-587")
        item.status = Imaging.StudyPreferenceStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StudyPreferenceStatus.draft) }
    }
}
