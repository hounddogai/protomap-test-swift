@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityTargetTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newModalityTarget("code-238", title: "title-475")
        #expect(item.status == Imaging.ModalityTargetStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Imaging.newModalityTarget("code-238", title: "title-475")
        try item.moveTo(Imaging.ModalityTargetStatus.inProgress)
        #expect(item.status == Imaging.ModalityTargetStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newModalityTarget("code-238", title: "title-475")
        item.status = Imaging.ModalityTargetStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalityTargetStatus.planned) }
    }
}
