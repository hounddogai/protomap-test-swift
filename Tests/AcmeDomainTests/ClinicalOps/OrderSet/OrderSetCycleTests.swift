@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetCycleTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newOrderSetCycle("code-697", name: "name-74")
        #expect(item.status == ClinicalOps.OrderSetCycleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = ClinicalOps.newOrderSetCycle("code-697", name: "name-74")
        try item.moveTo(ClinicalOps.OrderSetCycleStatus.withdrawn)
        #expect(item.status == ClinicalOps.OrderSetCycleStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newOrderSetCycle("code-697", name: "name-74")
        item.status = ClinicalOps.OrderSetCycleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetCycleStatus.proposed) }
    }
}
