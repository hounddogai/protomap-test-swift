@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryProgramBudgetTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newPrimaryProgramBudget("code-96", label: "label-235")
        #expect(item.status == CareManagement.PrimaryProgramBudgetStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = CareManagement.newPrimaryProgramBudget("code-96", label: "label-235")
        try item.moveTo(CareManagement.PrimaryProgramBudgetStatus.archived)
        #expect(item.status == CareManagement.PrimaryProgramBudgetStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newPrimaryProgramBudget("code-96", label: "label-235")
        item.status = CareManagement.PrimaryProgramBudgetStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.PrimaryProgramBudgetStatus.`open`) }
    }
}
