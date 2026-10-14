@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityGroupTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newModalityGroup("code-873", label: "label-637")
        #expect(item.status == Imaging.ModalityGroupStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Imaging.newModalityGroup("code-873", label: "label-637")
        try item.moveTo(Imaging.ModalityGroupStatus.validated)
        #expect(item.status == Imaging.ModalityGroupStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newModalityGroup("code-873", label: "label-637")
        item.status = Imaging.ModalityGroupStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalityGroupStatus.created) }
    }
}
