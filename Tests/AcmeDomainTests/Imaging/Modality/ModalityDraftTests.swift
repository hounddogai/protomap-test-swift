@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityDraftTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newModalityDraft("code-655", name: "name-214")
        #expect(item.status == Imaging.ModalityDraftStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Imaging.newModalityDraft("code-655", name: "name-214")
        try item.moveTo(Imaging.ModalityDraftStatus.expired)
        #expect(item.status == Imaging.ModalityDraftStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newModalityDraft("code-655", name: "name-214")
        item.status = Imaging.ModalityDraftStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalityDraftStatus.requested) }
    }
}
