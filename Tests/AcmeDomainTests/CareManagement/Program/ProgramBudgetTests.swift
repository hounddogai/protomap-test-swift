@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramBudgetTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newProgramBudget("code-713", title: "title-544")
        #expect(item.status == CareManagement.ProgramBudgetStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = CareManagement.newProgramBudget("code-713", title: "title-544")
        try item.moveTo(CareManagement.ProgramBudgetStatus.pending)
        #expect(item.status == CareManagement.ProgramBudgetStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newProgramBudget("code-713", title: "title-544")
        item.status = CareManagement.ProgramBudgetStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ProgramBudgetStatus.draft) }
    }
}
