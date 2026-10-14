@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityAdjustmentTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newModalityAdjustment("code-580", label: "label-8")
        #expect(item.status == Imaging.ModalityAdjustmentStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Imaging.newModalityAdjustment("code-580", label: "label-8")
        try item.moveTo(Imaging.ModalityAdjustmentStatus.published)
        #expect(item.status == Imaging.ModalityAdjustmentStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newModalityAdjustment("code-580", label: "label-8")
        item.status = Imaging.ModalityAdjustmentStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalityAdjustmentStatus.created) }
    }
}
