@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptiveStudyManifestTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newAdaptiveStudyManifest("code-558", label: "label-867")
        #expect(item.status == Imaging.AdaptiveStudyManifestStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Imaging.newAdaptiveStudyManifest("code-558", label: "label-867")
        try item.moveTo(Imaging.AdaptiveStudyManifestStatus.inReview)
        #expect(item.status == Imaging.AdaptiveStudyManifestStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newAdaptiveStudyManifest("code-558", label: "label-867")
        item.status = Imaging.AdaptiveStudyManifestStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.AdaptiveStudyManifestStatus.`open`) }
    }
}
