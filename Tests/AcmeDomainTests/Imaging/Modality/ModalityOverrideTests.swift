@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityOverrideTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newModalityOverride("code-984", name: "name-43")
        #expect(item.status == Imaging.ModalityOverrideStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Imaging.newModalityOverride("code-984", name: "name-43")
        try item.moveTo(Imaging.ModalityOverrideStatus.pending)
        #expect(item.status == Imaging.ModalityOverrideStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newModalityOverride("code-984", name: "name-43")
        item.status = Imaging.ModalityOverrideStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalityOverrideStatus.draft) }
    }
}
