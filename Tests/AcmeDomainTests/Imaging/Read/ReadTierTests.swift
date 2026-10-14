@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadTierTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newReadTier("code-672", label: "label-858")
        #expect(item.status == Imaging.ReadTierStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Imaging.newReadTier("code-672", label: "label-858")
        try item.moveTo(Imaging.ReadTierStatus.published)
        #expect(item.status == Imaging.ReadTierStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newReadTier("code-672", label: "label-858")
        item.status = Imaging.ReadTierStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ReadTierStatus.created) }
    }
}
