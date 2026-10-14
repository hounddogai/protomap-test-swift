@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingModalitySegmentTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newPendingModalitySegment("code-219", title: "title-576")
        #expect(item.status == Imaging.PendingModalitySegmentStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Imaging.newPendingModalitySegment("code-219", title: "title-576")
        try item.moveTo(Imaging.PendingModalitySegmentStatus.scheduled)
        #expect(item.status == Imaging.PendingModalitySegmentStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newPendingModalitySegment("code-219", title: "title-576")
        item.status = Imaging.PendingModalitySegmentStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PendingModalitySegmentStatus.planned) }
    }
}
