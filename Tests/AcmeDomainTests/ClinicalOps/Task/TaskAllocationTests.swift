@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskAllocationTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newTaskAllocation("code-789", label: "label-766")
        #expect(item.status == ClinicalOps.TaskAllocationStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = ClinicalOps.newTaskAllocation("code-789", label: "label-766")
        try item.moveTo(ClinicalOps.TaskAllocationStatus.rejected)
        #expect(item.status == ClinicalOps.TaskAllocationStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newTaskAllocation("code-789", label: "label-766")
        item.status = ClinicalOps.TaskAllocationStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TaskAllocationStatus.proposed) }
    }
}
