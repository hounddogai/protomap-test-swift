@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetSlotTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newOrderSetSlot("code-687", title: "title-869")
        #expect(item.status == ClinicalOps.OrderSetSlotStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = ClinicalOps.newOrderSetSlot("code-687", title: "title-869")
        try item.moveTo(ClinicalOps.OrderSetSlotStatus.rejected)
        #expect(item.status == ClinicalOps.OrderSetSlotStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newOrderSetSlot("code-687", title: "title-869")
        item.status = ClinicalOps.OrderSetSlotStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetSlotStatus.proposed) }
    }
}
