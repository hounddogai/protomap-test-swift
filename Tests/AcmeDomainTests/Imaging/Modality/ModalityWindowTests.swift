@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityWindowTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newModalityWindow("code-647", label: "label-499")
        #expect(item.status == Imaging.ModalityWindowStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Imaging.newModalityWindow("code-647", label: "label-499")
        try item.moveTo(Imaging.ModalityWindowStatus.validated)
        #expect(item.status == Imaging.ModalityWindowStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newModalityWindow("code-647", label: "label-499")
        item.status = Imaging.ModalityWindowStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalityWindowStatus.created) }
    }
}
