@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryStudyTargetTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newPrimaryStudyTarget("code-246", label: "label-734")
        #expect(item.status == Imaging.PrimaryStudyTargetStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Imaging.newPrimaryStudyTarget("code-246", label: "label-734")
        try item.moveTo(Imaging.PrimaryStudyTargetStatus.published)
        #expect(item.status == Imaging.PrimaryStudyTargetStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newPrimaryStudyTarget("code-246", label: "label-734")
        item.status = Imaging.PrimaryStudyTargetStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PrimaryStudyTargetStatus.created) }
    }
}
