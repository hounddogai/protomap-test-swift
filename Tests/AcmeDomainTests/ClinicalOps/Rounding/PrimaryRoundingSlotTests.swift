@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryRoundingSlotTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newPrimaryRoundingSlot("code-419", name: "name-690")
        #expect(item.status == ClinicalOps.PrimaryRoundingSlotStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = ClinicalOps.newPrimaryRoundingSlot("code-419", name: "name-690")
        try item.moveTo(ClinicalOps.PrimaryRoundingSlotStatus.pending)
        #expect(item.status == ClinicalOps.PrimaryRoundingSlotStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newPrimaryRoundingSlot("code-419", name: "name-690")
        item.status = ClinicalOps.PrimaryRoundingSlotStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.PrimaryRoundingSlotStatus.draft) }
    }
}
