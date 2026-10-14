@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingAllocationTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newRoundingAllocation("code-684", name: "name-302")
        #expect(item.status == ClinicalOps.RoundingAllocationStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = ClinicalOps.newRoundingAllocation("code-684", name: "name-302")
        try item.moveTo(ClinicalOps.RoundingAllocationStatus.approved)
        #expect(item.status == ClinicalOps.RoundingAllocationStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newRoundingAllocation("code-684", name: "name-302")
        item.status = ClinicalOps.RoundingAllocationStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RoundingAllocationStatus.proposed) }
    }
}
