@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackCareProtocolSegmentTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newFallbackCareProtocolSegment("code-716", title: "title-137")
        #expect(item.status == Imaging.FallbackCareProtocolSegmentStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Imaging.newFallbackCareProtocolSegment("code-716", title: "title-137")
        try item.moveTo(Imaging.FallbackCareProtocolSegmentStatus.rejected)
        #expect(item.status == Imaging.FallbackCareProtocolSegmentStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newFallbackCareProtocolSegment("code-716", title: "title-137")
        item.status = Imaging.FallbackCareProtocolSegmentStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.FallbackCareProtocolSegmentStatus.proposed) }
    }
}
