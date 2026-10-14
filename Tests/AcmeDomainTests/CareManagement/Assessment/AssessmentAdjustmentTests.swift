@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentAdjustmentTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newAssessmentAdjustment("code-631", label: "label-638")
        #expect(item.status == CareManagement.AssessmentAdjustmentStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = CareManagement.newAssessmentAdjustment("code-631", label: "label-638")
        try item.moveTo(CareManagement.AssessmentAdjustmentStatus.approved)
        #expect(item.status == CareManagement.AssessmentAdjustmentStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newAssessmentAdjustment("code-631", label: "label-638")
        item.status = CareManagement.AssessmentAdjustmentStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AssessmentAdjustmentStatus.proposed) }
    }
}
