@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientCareProtocolSegmentTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newLenientCareProtocolSegment("code-231", title: "title-100")
        #expect(item.status == Imaging.LenientCareProtocolSegmentStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Imaging.newLenientCareProtocolSegment("code-231", title: "title-100")
        try item.moveTo(Imaging.LenientCareProtocolSegmentStatus.draining)
        #expect(item.status == Imaging.LenientCareProtocolSegmentStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newLenientCareProtocolSegment("code-231", title: "title-100")
        item.status = Imaging.LenientCareProtocolSegmentStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.LenientCareProtocolSegmentStatus.idle) }
    }
}
