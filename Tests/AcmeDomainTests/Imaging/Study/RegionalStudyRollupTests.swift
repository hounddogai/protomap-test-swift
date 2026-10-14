@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalStudyRollupTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newRegionalStudyRollup("code-868", label: "label-748")
        #expect(item.status == Imaging.RegionalStudyRollupStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Imaging.newRegionalStudyRollup("code-868", label: "label-748")
        try item.moveTo(Imaging.RegionalStudyRollupStatus.published)
        #expect(item.status == Imaging.RegionalStudyRollupStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newRegionalStudyRollup("code-868", label: "label-748")
        item.status = Imaging.RegionalStudyRollupStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.RegionalStudyRollupStatus.created) }
    }
}
