@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityProfileTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newModalityProfile("code-802", title: "title-123")
        #expect(item.status == Imaging.ModalityProfileStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Imaging.newModalityProfile("code-802", title: "title-123")
        try item.moveTo(Imaging.ModalityProfileStatus.inProgress)
        #expect(item.status == Imaging.ModalityProfileStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newModalityProfile("code-802", title: "title-123")
        item.status = Imaging.ModalityProfileStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalityProfileStatus.planned) }
    }
}
