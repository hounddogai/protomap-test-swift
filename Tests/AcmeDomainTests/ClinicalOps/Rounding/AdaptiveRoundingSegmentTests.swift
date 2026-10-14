@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAdaptiveRoundingSegmentTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newAdaptiveRoundingSegment("code-578", name: "name-946")
        #expect(item.status == ClinicalOps.AdaptiveRoundingSegmentStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = ClinicalOps.newAdaptiveRoundingSegment("code-578", name: "name-946")
        try item.moveTo(ClinicalOps.AdaptiveRoundingSegmentStatus.rejected)
        #expect(item.status == ClinicalOps.AdaptiveRoundingSegmentStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newAdaptiveRoundingSegment("code-578", name: "name-946")
        item.status = ClinicalOps.AdaptiveRoundingSegmentStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AdaptiveRoundingSegmentStatus.proposed) }
    }
}
