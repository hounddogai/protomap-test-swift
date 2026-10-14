@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolSegmentTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newCareProtocolSegment("code-138", name: "name-816")
        #expect(item.status == Imaging.CareProtocolSegmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Imaging.newCareProtocolSegment("code-138", name: "name-816")
        try item.moveTo(Imaging.CareProtocolSegmentStatus.pending)
        #expect(item.status == Imaging.CareProtocolSegmentStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newCareProtocolSegment("code-138", name: "name-816")
        item.status = Imaging.CareProtocolSegmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CareProtocolSegmentStatus.draft) }
    }
}
