@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyManifestTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newStudyManifest("code-420", name: "name-24")
        #expect(item.status == Imaging.StudyManifestStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Imaging.newStudyManifest("code-420", name: "name-24")
        try item.moveTo(Imaging.StudyManifestStatus.validated)
        #expect(item.status == Imaging.StudyManifestStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newStudyManifest("code-420", name: "name-24")
        item.status = Imaging.StudyManifestStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StudyManifestStatus.created) }
    }
}
