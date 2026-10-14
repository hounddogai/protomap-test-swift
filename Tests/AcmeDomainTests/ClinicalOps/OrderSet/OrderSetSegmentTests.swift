@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetSegmentTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newOrderSetSegment("code-449", title: "title-500")
        #expect(item.status == ClinicalOps.OrderSetSegmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = ClinicalOps.newOrderSetSegment("code-449", title: "title-500")
        try item.moveTo(ClinicalOps.OrderSetSegmentStatus.suspended)
        #expect(item.status == ClinicalOps.OrderSetSegmentStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newOrderSetSegment("code-449", title: "title-500")
        item.status = ClinicalOps.OrderSetSegmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetSegmentStatus.draft) }
    }
}
