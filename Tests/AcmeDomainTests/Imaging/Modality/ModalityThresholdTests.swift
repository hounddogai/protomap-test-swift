@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityThresholdTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newModalityThreshold("code-766", title: "title-381")
        #expect(item.status == Imaging.ModalityThresholdStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Imaging.newModalityThreshold("code-766", title: "title-381")
        try item.moveTo(Imaging.ModalityThresholdStatus.completed)
        #expect(item.status == Imaging.ModalityThresholdStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newModalityThreshold("code-766", title: "title-381")
        item.status = Imaging.ModalityThresholdStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalityThresholdStatus.planned) }
    }
}
