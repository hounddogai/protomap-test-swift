@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityMappingTests {
    @Test func startsInNew() throws {
        let item = Imaging.newModalityMapping("code-677", name: "name-92")
        #expect(item.status == Imaging.ModalityMappingStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Imaging.newModalityMapping("code-677", name: "name-92")
        try item.moveTo(Imaging.ModalityMappingStatus.queued)
        #expect(item.status == Imaging.ModalityMappingStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newModalityMapping("code-677", name: "name-92")
        item.status = Imaging.ModalityMappingStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalityMappingStatus.new) }
    }
}
