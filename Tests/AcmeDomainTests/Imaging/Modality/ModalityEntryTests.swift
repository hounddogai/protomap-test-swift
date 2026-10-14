@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityEntryTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newModalityEntry("code-969", label: "label-566")
        #expect(item.status == Imaging.ModalityEntryStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Imaging.newModalityEntry("code-969", label: "label-566")
        try item.moveTo(Imaging.ModalityEntryStatus.scheduled)
        #expect(item.status == Imaging.ModalityEntryStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newModalityEntry("code-969", label: "label-566")
        item.status = Imaging.ModalityEntryStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalityEntryStatus.planned) }
    }
}
