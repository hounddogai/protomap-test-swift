@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetAdjustmentTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newOrderSetAdjustment("code-786", title: "title-174")
        #expect(item.status == ClinicalOps.OrderSetAdjustmentStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = ClinicalOps.newOrderSetAdjustment("code-786", title: "title-174")
        try item.moveTo(ClinicalOps.OrderSetAdjustmentStatus.completed)
        #expect(item.status == ClinicalOps.OrderSetAdjustmentStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newOrderSetAdjustment("code-786", title: "title-174")
        item.status = ClinicalOps.OrderSetAdjustmentStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetAdjustmentStatus.planned) }
    }
}
