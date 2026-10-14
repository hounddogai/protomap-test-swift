@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalAgreementTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newGoalAgreement("code-62", name: "name-447")
        #expect(item.status == CareManagement.GoalAgreementStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = CareManagement.newGoalAgreement("code-62", name: "name-447")
        try item.moveTo(CareManagement.GoalAgreementStatus.archived)
        #expect(item.status == CareManagement.GoalAgreementStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newGoalAgreement("code-62", name: "name-447")
        item.status = CareManagement.GoalAgreementStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GoalAgreementStatus.`open`) }
    }
}
