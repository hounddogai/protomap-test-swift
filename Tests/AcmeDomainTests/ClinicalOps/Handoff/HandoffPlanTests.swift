@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffPlanTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newHandoffPlan("code-411", name: "name-88")
        #expect(item.status == ClinicalOps.HandoffPlanStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = ClinicalOps.newHandoffPlan("code-411", name: "name-88")
        try item.moveTo(ClinicalOps.HandoffPlanStatus.completed)
        #expect(item.status == ClinicalOps.HandoffPlanStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newHandoffPlan("code-411", name: "name-88")
        item.status = ClinicalOps.HandoffPlanStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.HandoffPlanStatus.planned) }
    }
}
