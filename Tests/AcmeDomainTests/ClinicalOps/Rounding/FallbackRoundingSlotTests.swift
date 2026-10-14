@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackRoundingSlotTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newFallbackRoundingSlot("code-335", name: "name-333")
        #expect(item.status == ClinicalOps.FallbackRoundingSlotStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = ClinicalOps.newFallbackRoundingSlot("code-335", name: "name-333")
        try item.moveTo(ClinicalOps.FallbackRoundingSlotStatus.approved)
        #expect(item.status == ClinicalOps.FallbackRoundingSlotStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newFallbackRoundingSlot("code-335", name: "name-333")
        item.status = ClinicalOps.FallbackRoundingSlotStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.FallbackRoundingSlotStatus.proposed) }
    }
}
