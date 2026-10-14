@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredStudyTierTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newTieredStudyTier("code-699", label: "label-46")
        #expect(item.status == Imaging.TieredStudyTierStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Imaging.newTieredStudyTier("code-699", label: "label-46")
        try item.moveTo(Imaging.TieredStudyTierStatus.active)
        #expect(item.status == Imaging.TieredStudyTierStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newTieredStudyTier("code-699", label: "label-46")
        item.status = Imaging.TieredStudyTierStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.TieredStudyTierStatus.draft) }
    }
}
