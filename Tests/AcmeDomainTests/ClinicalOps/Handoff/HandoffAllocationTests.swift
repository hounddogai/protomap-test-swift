@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffAllocationTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newHandoffAllocation("code-388", title: "title-785")
        #expect(item.status == ClinicalOps.HandoffAllocationStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = ClinicalOps.newHandoffAllocation("code-388", title: "title-785")
        try item.moveTo(ClinicalOps.HandoffAllocationStatus.inProgress)
        #expect(item.status == ClinicalOps.HandoffAllocationStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newHandoffAllocation("code-388", title: "title-785")
        item.status = ClinicalOps.HandoffAllocationStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.HandoffAllocationStatus.planned) }
    }
}
