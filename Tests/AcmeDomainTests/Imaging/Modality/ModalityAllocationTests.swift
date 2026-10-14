@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityAllocationTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newModalityAllocation("code-828", label: "label-933")
        #expect(item.status == Imaging.ModalityAllocationStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Imaging.newModalityAllocation("code-828", label: "label-933")
        try item.moveTo(Imaging.ModalityAllocationStatus.inProgress)
        #expect(item.status == Imaging.ModalityAllocationStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newModalityAllocation("code-828", label: "label-933")
        item.status = Imaging.ModalityAllocationStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalityAllocationStatus.planned) }
    }
}
