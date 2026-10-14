@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskCycleTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newTaskCycle("code-694", name: "name-602")
        #expect(item.status == ClinicalOps.TaskCycleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = ClinicalOps.newTaskCycle("code-694", name: "name-602")
        try item.moveTo(ClinicalOps.TaskCycleStatus.scheduled)
        #expect(item.status == ClinicalOps.TaskCycleStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newTaskCycle("code-694", name: "name-602")
        item.status = ClinicalOps.TaskCycleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TaskCycleStatus.planned) }
    }
}
