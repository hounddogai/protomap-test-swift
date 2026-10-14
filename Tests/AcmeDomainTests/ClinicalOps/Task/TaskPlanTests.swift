@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskPlanTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newTaskPlan("code-785", label: "label-708")
        #expect(item.status == ClinicalOps.TaskPlanStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = ClinicalOps.newTaskPlan("code-785", label: "label-708")
        try item.moveTo(ClinicalOps.TaskPlanStatus.completed)
        #expect(item.status == ClinicalOps.TaskPlanStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newTaskPlan("code-785", label: "label-708")
        item.status = ClinicalOps.TaskPlanStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TaskPlanStatus.planned) }
    }
}
