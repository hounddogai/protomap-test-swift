@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingSegmentTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newRoundingSegment("code-768", name: "name-775")
        #expect(item.status == ClinicalOps.RoundingSegmentStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = ClinicalOps.newRoundingSegment("code-768", name: "name-775")
        try item.moveTo(ClinicalOps.RoundingSegmentStatus.inReview)
        #expect(item.status == ClinicalOps.RoundingSegmentStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newRoundingSegment("code-768", name: "name-775")
        item.status = ClinicalOps.RoundingSegmentStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RoundingSegmentStatus.`open`) }
    }
}
