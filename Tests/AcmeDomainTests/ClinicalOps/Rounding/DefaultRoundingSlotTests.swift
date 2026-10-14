@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultRoundingSlotTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newDefaultRoundingSlot("code-417", title: "title-934")
        #expect(item.status == ClinicalOps.DefaultRoundingSlotStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = ClinicalOps.newDefaultRoundingSlot("code-417", title: "title-934")
        try item.moveTo(ClinicalOps.DefaultRoundingSlotStatus.closed)
        #expect(item.status == ClinicalOps.DefaultRoundingSlotStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newDefaultRoundingSlot("code-417", title: "title-934")
        item.status = ClinicalOps.DefaultRoundingSlotStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.DefaultRoundingSlotStatus.draft) }
    }
}
