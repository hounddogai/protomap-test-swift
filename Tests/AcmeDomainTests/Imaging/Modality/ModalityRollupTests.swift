@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityRollupTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newModalityRollup("code-981", title: "title-468")
        #expect(item.status == Imaging.ModalityRollupStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Imaging.newModalityRollup("code-981", title: "title-468")
        try item.moveTo(Imaging.ModalityRollupStatus.active)
        #expect(item.status == Imaging.ModalityRollupStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newModalityRollup("code-981", title: "title-468")
        item.status = Imaging.ModalityRollupStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalityRollupStatus.draft) }
    }
}
