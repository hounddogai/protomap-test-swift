@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalitySegmentTests {
    @Test func startsInNew() throws {
        let item = Imaging.newModalitySegment("code-827", title: "title-235")
        #expect(item.status == Imaging.ModalitySegmentStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Imaging.newModalitySegment("code-827", title: "title-235")
        try item.moveTo(Imaging.ModalitySegmentStatus.running)
        #expect(item.status == Imaging.ModalitySegmentStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newModalitySegment("code-827", title: "title-235")
        item.status = Imaging.ModalitySegmentStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalitySegmentStatus.new) }
    }
}
