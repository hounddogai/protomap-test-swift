@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalitySlotTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newModalitySlot("code-583", label: "label-518")
        #expect(item.status == Imaging.ModalitySlotStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Imaging.newModalitySlot("code-583", label: "label-518")
        try item.moveTo(Imaging.ModalitySlotStatus.withdrawn)
        #expect(item.status == Imaging.ModalitySlotStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newModalitySlot("code-583", label: "label-518")
        item.status = Imaging.ModalitySlotStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalitySlotStatus.proposed) }
    }
}
