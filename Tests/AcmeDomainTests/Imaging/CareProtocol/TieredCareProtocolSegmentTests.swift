@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredCareProtocolSegmentTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newTieredCareProtocolSegment("code-816", label: "label-10")
        #expect(item.status == Imaging.TieredCareProtocolSegmentStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Imaging.newTieredCareProtocolSegment("code-816", label: "label-10")
        try item.moveTo(Imaging.TieredCareProtocolSegmentStatus.approved)
        #expect(item.status == Imaging.TieredCareProtocolSegmentStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newTieredCareProtocolSegment("code-816", label: "label-10")
        item.status = Imaging.TieredCareProtocolSegmentStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.TieredCareProtocolSegmentStatus.proposed) }
    }
}
