@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalAssessmentRuleTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newGlobalAssessmentRule("code-528", name: "name-183")
        #expect(item.status == CareManagement.GlobalAssessmentRuleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = CareManagement.newGlobalAssessmentRule("code-528", name: "name-183")
        try item.moveTo(CareManagement.GlobalAssessmentRuleStatus.approved)
        #expect(item.status == CareManagement.GlobalAssessmentRuleStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newGlobalAssessmentRule("code-528", name: "name-183")
        item.status = CareManagement.GlobalAssessmentRuleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GlobalAssessmentRuleStatus.proposed) }
    }
}
