@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredAssessmentAllocationTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newTieredAssessmentAllocation("code-131", label: "label-865")
        #expect(item.status == CareManagement.TieredAssessmentAllocationStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = CareManagement.newTieredAssessmentAllocation("code-131", label: "label-865")
        try item.moveTo(CareManagement.TieredAssessmentAllocationStatus.approved)
        #expect(item.status == CareManagement.TieredAssessmentAllocationStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newTieredAssessmentAllocation("code-131", label: "label-865")
        item.status = CareManagement.TieredAssessmentAllocationStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.TieredAssessmentAllocationStatus.proposed) }
    }
}
